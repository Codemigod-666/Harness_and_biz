/** A declared outcome: the value, or the failure the contract allows (TS-6). */
export interface Success<T> {
    readonly ok: true;
    readonly value: T;
}
export interface Failure<E> {
    readonly ok: false;
    readonly failure: E;
}
export type Result<T, E> = Success<T> | Failure<E>;

export const ok = <T>(value: T): Success<T> => ({ ok: true, value });
export const fail = <E>(failure: E): Failure<E> => ({ ok: false, failure });
