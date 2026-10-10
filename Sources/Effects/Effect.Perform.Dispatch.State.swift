public import Effect

extension Effect.Perform.Dispatch {
    @usableFromInline
    enum State {
        case pending
        case stored(Task<Void, Never>)
        case cancelledBeforeStore
    }
}
