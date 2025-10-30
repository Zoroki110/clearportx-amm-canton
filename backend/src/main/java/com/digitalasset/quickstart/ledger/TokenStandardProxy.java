// Copyright (c) 2025, Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
// SPDX-License-Identifier: 0BSD

package com.clearportx.ledger;

import com.clearportx.config.LedgerConfig;
import com.clearportx.tokenstandard.openapi.ApiClient;
import com.clearportx.tokenstandard.openapi.ApiException;
import com.clearportx.tokenstandard.openapi.allocation.DefaultAllocationApi;
import com.clearportx.tokenstandard.openapi.allocation.model.ChoiceContext;
import com.clearportx.tokenstandard.openapi.allocation.model.GetChoiceContextRequest;
import com.clearportx.tokenstandard.openapi.metadata.DefaultMetadataApi;
import com.clearportx.tokenstandard.openapi.metadata.model.GetRegistryInfoResponse;
import com.clearportx.utility.TracingUtils;
import com.clearportx.utility.TracingUtils.TracingContext;
import io.opentelemetry.instrumentation.annotations.WithSpan;

import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import static com.clearportx.utility.TracingUtils.tracingCtx;

@Component
public class TokenStandardProxy {
    private final DefaultAllocationApi allocationApi;
    private final DefaultMetadataApi metadataApi;

    private static final Logger logger = LoggerFactory.getLogger(TokenStandardProxy.class);

    public TokenStandardProxy(LedgerConfig ledgerConfig) {
        ApiClient apiClient = new ApiClient();
        apiClient.updateBaseUri(ledgerConfig.getRegistryBaseUri());
        this.allocationApi = new DefaultAllocationApi(apiClient);
        this.metadataApi = new DefaultMetadataApi(apiClient);
    }

    @WithSpan
    public CompletableFuture<String> getRegistryAdminId() {
        var ctx = tracingCtx(logger, "getRegistryAdminId");
        return trace(ctx, () ->
                metadataApi.getRegistryInfo().thenApply(GetRegistryInfoResponse::getAdminId)
        );
    }

    @WithSpan
    public CompletableFuture<Optional<ChoiceContext>> getAllocationTransferContext(String allocationId) {
        var ctx = tracingCtx(logger, "getAllocationTransferContext",
                "allocationId", allocationId
        );
        return trace(ctx, () ->
                allocationApi.getAllocationTransferContext(allocationId, new GetChoiceContextRequest()).thenApply(Optional::ofNullable)
        );
    }

    private <T> CompletableFuture<T> trace(
            TracingContext ctx,
            ThrowingSupplier<CompletableFuture<T>> supplier) {
        return TracingUtils.trace(ctx, () -> {
            try {
                return supplier.get();
                // should not be possible - OpenAPI codegen adds false checked `throws` declaration
            } catch (ApiException e) {
                throw new CompletionException(e);
            }
        });
    }

    @FunctionalInterface
    private interface ThrowingSupplier<T> {
        T get() throws ApiException;
    }
}
