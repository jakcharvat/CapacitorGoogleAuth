package dev.jakcharvat.capacitorgoogleauth

internal inline fun <T> tryOrNull(f: () -> T) =
    try {
        f()
    } catch (_: Exception) {
        null
    }
