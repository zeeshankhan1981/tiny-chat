import Foundation
import llamaforked

@preconcurrency actor LlamaContext {
    nonisolated(unsafe) private var model: OpaquePointer
    nonisolated(unsafe) private var context: OpaquePointer
    nonisolated(unsafe) private var batch: llama_batch
    private var tokens_list: [llama_token]
    private var temporary_invalid_cchars: [CChar]

    var n_len: Int32 = 128
    var n_cur: Int32 = 0
    var n_decode: Int32 = 0

    init(model: OpaquePointer, context: OpaquePointer) {
        self.model = model
        self.context = context
        self.batch = llama_batch_init(512, 0, 1)
        self.tokens_list = []
        self.temporary_invalid_cchars = []
    }

    deinit {
        llama_batch_free(batch)
        llama_free(context)
        llama_free_model(model)
        llama_backend_free()
    }

    static func create_context(path: String) throws -> LlamaContext {
        llama_backend_init()
        var model_params = llama_model_default_params()

        #if targetEnvironment(simulator)
        model_params.n_gpu_layers = 0
        print("Running on simulator, force use n_gpu_layers = 0")
        #endif

        guard let model = llama_load_model_from_file(path, model_params) else {
            print("Could not load model at \(path)")
            throw LlamaError.couldNotInitializeContext
        }

        var ctx_params = llama_context_default_params()
        ctx_params.seed = 1234
        ctx_params.n_ctx = 2048

        let n_threads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        ctx_params.n_threads = UInt32(n_threads)
        ctx_params.n_threads_batch = UInt32(n_threads)

        guard let context = llama_new_context_with_model(model, ctx_params) else {
            print("Could not create context")
            throw LlamaError.couldNotInitializeContext
        }

        return LlamaContext(model: model, context: context)
    }

    func completion_init(text: String) {
        tokens_list = tokenize(text: text, add_bos: true)
        temporary_invalid_cchars = []

        llama_batch_clear(&batch)
        for (i, token) in tokens_list.enumerated() {
            llama_batch_add(&batch, token, Int32(i), [0], false)
        }
        batch.logits[Int(batch.n_tokens) - 1] = 1

        _ = llama_decode(context, batch)
        n_cur = batch.n_tokens
    }

    func completion_loop() -> String {
        let n_vocab = llama_n_vocab(model)
        let logits = llama_get_logits_ith(context, batch.n_tokens - 1)
        guard logits != nil else { return "" }

        var candidates = (0..<n_vocab).map {
            llama_token_data(id: $0, logit: logits![Int($0)], p: 0)
        }

        var candidates_p = llama_token_data_array(data: &candidates, size: candidates.count, sorted: false)
        let new_token_id = llama_sample_token_greedy(context, &candidates_p)

        if new_token_id == llama_token_eos(model) || n_cur == n_len {
            let str = String(cString: temporary_invalid_cchars + [0])
            temporary_invalid_cchars.removeAll()
            return str
        }

        let new_token_cchars = token_to_piece(token: new_token_id)
        temporary_invalid_cchars.append(contentsOf: new_token_cchars)

        let result: String
        if let str = String(validatingUTF8: temporary_invalid_cchars + [0]) {
            result = str
            temporary_invalid_cchars.removeAll()
        } else {
            result = ""
        }

        llama_batch_clear(&batch)
        llama_batch_add(&batch, new_token_id, n_cur, [0], true)
        _ = llama_decode(context, batch)

        n_decode += 1
        n_cur += 1

        return result
    }

    func clear() {
        tokens_list.removeAll()
        temporary_invalid_cchars.removeAll()
        llama_kv_cache_clear(context)
    }

    private func tokenize(text: String, add_bos: Bool) -> [llama_token] {
        let n_tokens = text.utf8.count + (add_bos ? 1 : 0) + 1
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: n_tokens)
        let count = llama_tokenize(model, text, Int32(text.utf8.count), tokens, Int32(n_tokens), add_bos, false)
        defer { tokens.deallocate() }

        return (0..<count).map { tokens[Int($0)] }
    }

    private func token_to_piece(token: llama_token) -> [CChar] {
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
        defer { result.deallocate() }
        let n = llama_token_to_piece(model, token, result, 8)

        if n < 0 {
            let size = -n
            let newResult = UnsafeMutablePointer<Int8>.allocate(capacity: Int(size))
            defer { newResult.deallocate() }
            let newN = llama_token_to_piece(model, token, newResult, size)
            return Array(UnsafeBufferPointer(start: newResult, count: Int(newN)))
        } else {
            return Array(UnsafeBufferPointer(start: result, count: Int(n)))
        }
    }
}

enum LlamaError: Error {
    case couldNotInitializeContext
}

// MARK: - Batch Helpers

func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

func llama_batch_add(_ batch: inout llama_batch, _ id: llama_token, _ pos: llama_pos, _ seq_ids: [llama_seq_id], _ logits: Bool) {
    let idx = Int(batch.n_tokens)
    batch.token[idx] = id
    batch.pos[idx] = pos
    batch.n_seq_id[idx] = Int32(seq_ids.count)

    for (i, sid) in seq_ids.enumerated() {
        batch.seq_id[idx]![i] = sid
    }

    batch.logits[idx] = logits ? 1 : 0
    batch.n_tokens += 1
}
