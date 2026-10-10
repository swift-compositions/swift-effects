public import Dependency
public import Effect

extension Effect.Handled {
    public protocol `Protocol`: Effect.`Protocol` {
        associatedtype HandlerKey: Dependency.Key
        where HandlerKey.Value: Effect.Handler.`Protocol`, HandlerKey.Value.Handled == Self
    }
}
