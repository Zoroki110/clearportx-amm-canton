package com.clearportx.config;

import com.daml.ledger.javaapi.data.DamlRecord;
import com.daml.ledger.javaapi.data.Party;
import com.daml.ledger.rxjava.DamlLedgerClient;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CantonConfig {

    @Value("${canton.participant.host}")
    private String cantonHost;

    @Value("${canton.participant.port}")
    private int cantonPort;

    @Value("${canton.party.pool-operator}")
    private String poolOperatorParty;

    @Bean
    public DamlLedgerClient damlLedgerClient() {
        ManagedChannel channel = ManagedChannelBuilder
                .forAddress(cantonHost, cantonPort)
                .usePlaintext()
                .build();

        return DamlLedgerClient.newBuilder(channel).build();
    }

    @Bean
    public Party poolOperator() {
        return new Party(poolOperatorParty);
    }
}
