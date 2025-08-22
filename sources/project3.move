module MyModule::StudyCoordination {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a multi-center research study.
    struct Study has store, key {
        study_id: u64,           // Unique identifier for the study
        total_centers: u64,      // Number of centers participating
        total_funding: u64,      // Total funding allocated to the study
        start_time: u64,         // Study start timestamp
        is_active: bool,         // Whether the study is currently active
        coordinator: address,    // Address of the study coordinator
    }

    /// Struct representing a research center's participation.
    struct CenterParticipation has store, key {
        center_id: u64,          // Unique center identifier
        allocated_funding: u64,  // Funding allocated to this center
        data_submissions: u64,   // Number of data submissions from center
        joined_at: u64,          // Timestamp when center joined
    }

    /// Function to initialize a new multi-center study.
    public fun create_study(
        coordinator: &signer, 
        study_id: u64, 
        total_funding: u64
    ) {
        let coordinator_addr = signer::address_of(coordinator);
        let study = Study {
            study_id,
            total_centers: 0,
            total_funding,
            start_time: timestamp::now_seconds(),
            is_active: true,
            coordinator: coordinator_addr,
        };
        move_to(coordinator, study);
    }

    /// Function for research centers to join study and receive funding allocation.
    public fun join_study_center(
        center: &signer,
        study_coordinator: address,
        center_id: u64,
        requested_funding: u64
    ) acquires Study {
        let study = borrow_global_mut<Study>(study_coordinator);
        
        // Verify study is active and has sufficient funding
        assert!(study.is_active, 1);
        assert!(study.total_funding >= requested_funding, 2);
        
        // Create center participation record
        let center_participation = CenterParticipation {
            center_id,
            allocated_funding: requested_funding,
            data_submissions: 0,
            joined_at: timestamp::now_seconds(),
        };
        
        // Transfer funding to the center
        let funding = coin::withdraw<AptosCoin>(
            &signer::create_signer_with_capability(&study.coordinator), 
            requested_funding
        );
        coin::deposit<AptosCoin>(signer::address_of(center), funding);
        
        // Update study metrics
        study.total_centers = study.total_centers + 1;
        study.total_funding = study.total_funding - requested_funding;
        
        move_to(center, center_participation);
    }
}