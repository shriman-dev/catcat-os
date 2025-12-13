import { findActorBy } from '../../utils/utils.js';

/**
 * Extracts the prototype of [Keyboard.Key] from the given [Keyboard.Keyboard] instance
 * since it is not exported.
 */
function extractKeyPrototype(keyboard) {
    if (_keyProtoCache != null)
        return _keyProtoCache;
    let r = findActorBy(keyboard._aspectContainer, a => a.constructor.name === 'Key' && !!Object.getPrototypeOf(a));
    _keyProtoCache = r !== null
        ? Object.getPrototypeOf(r)
        : null;
    return _keyProtoCache;
}
let _keyProtoCache = null;

export { extractKeyPrototype };
