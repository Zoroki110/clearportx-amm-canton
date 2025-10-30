package com.clearportx.controller;

import clearportx_amm_production_production.amm.pool.Pool;
import clearportx_amm_production_production.token.token.Token;
import com.clearportx.ledger.LedgerApi;
import com.digitalasset.transcode.java.Party;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/test")
public class TestSwapController {
    private static final Logger logger = LoggerFactory.getLogger(TestSwapController.class);
    private final LedgerApi ledger;

    // Fixed party for testing
    private static final String TEST_PARTY = "app_provider_quickstart-root-1::12201300e204e8a38492e7df0ca7cf67ec3fe3355407903a72323fd72da9f368a45d";

    public TestSwapController(LedgerApi ledger) {
        this.ledger = ledger;
    }

    @GetMapping("/swap-test")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> testSwap() {
        logger.info("TEST SWAP ENDPOINT - No auth required");
        Map<String, Object> result = new HashMap<>();

        try {
            // Step 1: Mint 1 ETH
            logger.info("Minting 1 ETH for test party: {}", TEST_PARTY);
            Token ethToken = new Token(
                new Party(TEST_PARTY),
                new Party(TEST_PARTY),
                "ETH",
                new BigDecimal("1.0")
            );

            String commandId = "test-mint-" + UUID.randomUUID();
            var ethTokenCid = ledger.createAndGetCid(
                ethToken,
                List.of(TEST_PARTY),
                Collections.emptyList(),
                commandId,
                clearportx_amm_production_production.Identifiers.Token_Token__Token
            ).join();

            result.put("ethTokenCid", ethTokenCid.getContractId);

            // Step 2: Find pool
            var pools = ledger.getActiveContracts(Pool.class).join();
            if (pools.isEmpty()) {
                result.put("error", "No pools found");
                return CompletableFuture.completedFuture(ResponseEntity.ok(result));
            }

            var pool = pools.get(0);
            result.put("poolId", pool.payload.getPoolId);
            result.put("reserveA_before", pool.payload.getReserveA);
            result.put("reserveB_before", pool.payload.getReserveB);

            // Step 3: Try atomic swap (if available)
            // For now, just return pool info
            result.put("status", "Test complete - ETH minted, pool found");
            result.put("message", "Swap execution would happen here if AtomicSwap was properly configured");

            return CompletableFuture.completedFuture(ResponseEntity.ok(result));

        } catch (Exception e) {
            logger.error("Test swap failed", e);
            result.put("error", e.getMessage());
            return CompletableFuture.completedFuture(ResponseEntity.status(500).body(result));
        }
    }
}