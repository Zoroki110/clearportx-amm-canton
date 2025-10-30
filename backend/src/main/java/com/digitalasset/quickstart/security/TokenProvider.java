package com.clearportx.security;

public interface TokenProvider {
    /**
     * Get the JWT token for backend channels.
     */
    String getToken();
}
