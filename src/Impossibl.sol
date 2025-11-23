// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ImpossiblProtocol
 * @author Impossibl Team
 * @notice A protocol for managing tournaments with two types: Global and Group
 * @dev Global tournaments use Merkle proofs for winner verification, while Group tournaments have a single winner
 *      Supports both ETH and ERC20 token buy-ins and prize distributions
 */
contract ImpossiblProtocol is Ownable {
    using MerkleProof for bytes32[];

    // ============================================================================
    // Type Definitions
    // ============================================================================

    /**
     * @notice Tournament type enumeration
     * @dev Global tournaments use Merkle proofs for multiple winners
     *      Group tournaments have a single winner set by the owner
     */
    enum TournamentType {
        Global,
        Group
    }

    /**
     * @notice Tournament status enumeration
     * @dev Active tournaments can accept participants
     *      Completed tournaments have winners set and prizes can be claimed
     */
    enum TournamentStatus {
        Active,
        Completed
    }

    /**
     * @notice Tournament structure containing all tournament data
     * @param id Unique tournament identifier
     * @param tournamentType Type of tournament (Global or Group)
     * @param status Current status of the tournament (Active or Completed)
     * @param buyInToken Address of the ERC20 token for buy-in (address(0) for ETH)
     * @param buyInAmount Amount required to join the tournament
     * @param prizePool Total amount accumulated in the prize pool
     * @param creator Address that created the tournament
     * @param createdAt Timestamp when the tournament was created
     * @param winner Winner address for Group tournaments (single winner)
     * @param merkleRoot Merkle root for Global tournaments (contains winner information)
     */
    struct Tournament {
        uint256 id;
        TournamentType tournamentType;
        TournamentStatus status;
        address buyInToken; // address(0) for ETH, otherwise ERC20 token address
        uint256 buyInAmount;
        uint256 prizePool;
        address creator;
        uint256 createdAt;
        address winner; // For Group tournaments: single winner address
        bytes32 merkleRoot; // For Global tournaments: Merkle root of winners
    }

    // ============================================================================
    // State Variables
    // ============================================================================

    /// @notice Mapping from tournament ID to tournament data
    mapping(uint256 => Tournament) public tournaments;

    /// @notice Mapping from tournament ID to participant addresses
    /// @dev Used to track which addresses have joined each tournament
    mapping(uint256 => mapping(address => bool)) public participants;

    /// @notice Mapping from tournament ID to claimed amounts per participant
    /// @dev Used for Global tournaments to track how much each participant has claimed
    mapping(uint256 => mapping(address => uint256)) public claimedAmounts;

    /// @notice Counter for generating unique tournament IDs
    uint256 public nextTournamentId;

    // ============================================================================
    // Events
    // ============================================================================

    /**
     * @notice Emitted when a new tournament is created
     * @param tournamentId Unique identifier of the tournament
     * @param tournamentType Type of tournament (Global or Group)
     * @param creator Address that created the tournament
     * @param buyInToken Token address used for buy-in (address(0) for ETH)
     * @param buyInAmount Amount required to join the tournament
     */
    event TournamentCreated(
        uint256 indexed tournamentId,
        TournamentType tournamentType,
        address indexed creator,
        address buyInToken,
        uint256 buyInAmount
    );

    /**
     * @notice Emitted when a participant joins a tournament
     * @param tournamentId ID of the tournament joined
     * @param participant Address of the participant
     * @param amount Buy-in amount paid
     */
    event TournamentJoined(
        uint256 indexed tournamentId,
        address indexed participant,
        uint256 amount
    );

    /**
     * @notice Emitted when a winner is set for a Group tournament
     * @param tournamentId ID of the tournament
     * @param winner Address of the winner
     * @param prizeAmount Amount of prize distributed to the winner
     */
    event GroupWinnerSet(
        uint256 indexed tournamentId,
        address indexed winner,
        uint256 prizeAmount
    );

    /**
     * @notice Emitted when a Merkle root is set for a Global tournament
     * @param tournamentId ID of the tournament
     * @param merkleRoot Merkle root containing winner information
     */
    event GlobalMerkleRootSet(
        uint256 indexed tournamentId,
        bytes32 merkleRoot
    );

    /**
     * @notice Emitted when a prize is claimed from a Global tournament
     * @param tournamentId ID of the tournament
     * @param winner Address that claimed the prize
     * @param amount Amount claimed
     */
    event PrizeClaimed(
        uint256 indexed tournamentId,
        address indexed winner,
        uint256 amount
    );

    // ============================================================================
    // Constructor
    // ============================================================================

    /**
     * @notice Initializes the contract and sets the deployer as the owner
     * @dev Uses OpenZeppelin's Ownable pattern for access control
     */
    constructor() Ownable(msg.sender) {}

    // ============================================================================
    // Tournament Creation Functions
    // ============================================================================

    /**
     * @notice Create a new Global tournament
     * @dev Global tournaments use Merkle proofs to verify winners after completion
     *      Multiple winners can be specified in the Merkle tree
     * @param buyInToken Address of the ERC20 token for buy-in (address(0) for ETH)
     * @param buyInAmount Amount required to join the tournament
     * @return tournamentId The unique identifier of the created tournament
     */
    function createGlobalTournament(
        address buyInToken,
        uint256 buyInAmount
    ) external onlyOwner returns (uint256) {
        uint256 tournamentId = nextTournamentId++;
        
        tournaments[tournamentId] = Tournament({
            id: tournamentId,
            tournamentType: TournamentType.Global,
            status: TournamentStatus.Active,
            buyInToken: buyInToken,
            buyInAmount: buyInAmount,
            prizePool: 0,
            creator: msg.sender,
            createdAt: block.timestamp,
            winner: address(0),
            merkleRoot: bytes32(0)
        });

        emit TournamentCreated(
            tournamentId,
            TournamentType.Global,
            msg.sender,
            buyInToken,
            buyInAmount
        );

        return tournamentId;
    }

    /**
     * @notice Create a new Group tournament
     * @dev Group tournaments have a single winner set by the owner
     *      Prize is automatically distributed when winner is set
     * @param buyInToken Address of the ERC20 token for buy-in (address(0) for ETH)
     * @param buyInAmount Amount required to join the tournament
     * @return tournamentId The unique identifier of the created tournament
     */
    function createGroupTournament(
        address buyInToken,
        uint256 buyInAmount
    ) external onlyOwner returns (uint256) {
        uint256 tournamentId = nextTournamentId++;
        
        tournaments[tournamentId] = Tournament({
            id: tournamentId,
            tournamentType: TournamentType.Group,
            status: TournamentStatus.Active,
            buyInToken: buyInToken,
            buyInAmount: buyInAmount,
            prizePool: 0,
            creator: msg.sender,
            createdAt: block.timestamp,
            winner: address(0),
            merkleRoot: bytes32(0)
        });

        emit TournamentCreated(
            tournamentId,
            TournamentType.Group,
            msg.sender,
            buyInToken,
            buyInAmount
        );

        return tournamentId;
    }

    // ============================================================================
    // Tournament Participation Functions
    // ============================================================================

    /**
     * @notice Join a tournament by paying the buy-in amount
     * @dev Supports both ETH and ERC20 token buy-ins
     *      The player address can be different from msg.sender (allows proxy payments)
     * @param tournamentId ID of the tournament to join
     * @param player Address of the player to register (payment is from msg.sender)
     * @custom:requirements Tournament must be active
     * @custom:requirements Player address must be valid (non-zero)
     * @custom:requirements Player must not have already joined
     * @custom:requirements Correct buy-in amount must be paid
     */
    function joinTournament(
        uint256 tournamentId,
        address player
    ) external payable {
        Tournament storage tournament = tournaments[tournamentId];
        
        require(
            tournament.status == TournamentStatus.Active,
            "Tournament is not active"
        );
        require(player != address(0), "Invalid player address");
        require(
            !participants[tournamentId][player],
            "Already joined this tournament"
        );

        participants[tournamentId][player] = true;

        if (tournament.buyInToken == address(0)) {
            // ETH buy-in
            require(
                msg.value == tournament.buyInAmount,
                "Incorrect ETH amount"
            );
            tournament.prizePool += msg.value;
        } else {
            // ERC20 buy-in
            require(msg.value == 0, "ETH not accepted for this tournament");
            IERC20 token = IERC20(tournament.buyInToken);
            require(
                token.transferFrom(
                    msg.sender,
                    address(this),
                    tournament.buyInAmount
                ),
                "Token transfer failed"
            );
            tournament.prizePool += tournament.buyInAmount;
        }

        emit TournamentJoined(tournamentId, player, tournament.buyInAmount);
    }

    // ============================================================================
    // Tournament Management Functions (Owner Only)
    // ============================================================================

    /**
     * @notice Set the winner for a Group tournament and distribute the prize
     * @dev Only callable by the contract owner
     *      Automatically transfers the entire prize pool to the winner
     *      Marks the tournament as completed
     * @param tournamentId ID of the group tournament
     * @param winner Address of the winner
     * @custom:requirements Tournament must be a Group type
     * @custom:requirements Tournament must be active
     * @custom:requirements Winner must be a valid participant
     */
    function setGroupWinner(
        uint256 tournamentId,
        address winner
    ) external onlyOwner {
        Tournament storage tournament = tournaments[tournamentId];
        
        require(
            tournament.tournamentType == TournamentType.Group,
            "Not a group tournament"
        );
        require(
            tournament.status == TournamentStatus.Active,
            "Tournament is not active"
        );
        require(winner != address(0), "Invalid winner address");
        require(
            participants[tournamentId][winner],
            "Winner must be a participant"
        );

        tournament.winner = winner;
        tournament.status = TournamentStatus.Completed;

        // Automatically distribute prize pool to winner
        uint256 prizeAmount = tournament.prizePool;
        tournament.prizePool = 0;

        if (tournament.buyInToken == address(0)) {
            // ETH prize
            (bool success, ) = winner.call{value: prizeAmount}("");
            require(success, "ETH transfer failed");
        } else {
            // ERC20 prize
            IERC20 token = IERC20(tournament.buyInToken);
            require(
                token.transfer(winner, prizeAmount),
                "Token transfer failed"
            );
        }

        emit GroupWinnerSet(tournamentId, winner, prizeAmount);
    }

    /**
     * @notice Set the Merkle root for a Global tournament
     * @dev Only callable by the contract owner
     *      The Merkle root should contain all winner addresses and their prize amounts
     *      Marks the tournament as completed, allowing winners to claim prizes
     * @param tournamentId ID of the global tournament
     * @param merkleRoot Merkle root containing winner information
     * @custom:requirements Tournament must be a Global type
     * @custom:requirements Tournament must be active
     * @custom:requirements Merkle root must be non-zero
     */
    function setGlobalWinnerMerkleRoot(
        uint256 tournamentId,
        bytes32 merkleRoot
    ) external onlyOwner {
        Tournament storage tournament = tournaments[tournamentId];
        
        require(
            tournament.tournamentType == TournamentType.Global,
            "Not a global tournament"
        );
        require(
            tournament.status == TournamentStatus.Active,
            "Tournament is not active"
        );
        require(merkleRoot != bytes32(0), "Invalid merkle root");

        tournament.merkleRoot = merkleRoot;
        tournament.status = TournamentStatus.Completed;

        emit GlobalMerkleRootSet(tournamentId, merkleRoot);
    }

    // ============================================================================
    // Prize Claim Functions
    // ============================================================================

    /**
     * @notice Claim prize for a Global tournament using Merkle proof
     * @dev Winners must provide a valid Merkle proof to claim their prize
     *      Supports partial claims - if a winner claims less than their total,
     *      they can claim the remainder later
     * @param tournamentId ID of the global tournament
     * @param amount Total amount the winner is entitled to claim
     * @param proof Merkle proof verifying the winner's entitlement
     * @custom:requirements Tournament must be a Global type
     * @custom:requirements Tournament must be completed
     * @custom:requirements Merkle root must be set
     * @custom:requirements Merkle proof must be valid
     * @custom:requirements Claim amount must be greater than already claimed
     */
    function claimPrize(
        uint256 tournamentId,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        Tournament storage tournament = tournaments[tournamentId];
        
        require(
            tournament.tournamentType == TournamentType.Global,
            "Not a global tournament"
        );
        require(
            tournament.status == TournamentStatus.Completed,
            "Tournament is not completed"
        );
        require(
            tournament.merkleRoot != bytes32(0),
            "Merkle root not set"
        );
        require(amount > 0, "Amount must be greater than 0");

        // Verify merkle proof
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        require(
            proof.verify(tournament.merkleRoot, leaf),
            "Invalid merkle proof"
        );

        // Check if already claimed
        uint256 alreadyClaimed = claimedAmounts[tournamentId][msg.sender];
        require(
            alreadyClaimed < amount,
            "Already claimed this amount or more"
        );

        uint256 claimableAmount = amount - alreadyClaimed;
        require(
            claimableAmount <= tournament.prizePool,
            "Insufficient prize pool"
        );

        // Update claimed amount
        claimedAmounts[tournamentId][msg.sender] = amount;
        tournament.prizePool -= claimableAmount;

        // Transfer prize
        if (tournament.buyInToken == address(0)) {
            // ETH prize
            (bool success, ) = msg.sender.call{value: claimableAmount}("");
            require(success, "ETH transfer failed");
        } else {
            // ERC20 prize
            IERC20 token = IERC20(tournament.buyInToken);
            require(
                token.transfer(msg.sender, claimableAmount),
                "Token transfer failed"
            );
        }

        emit PrizeClaimed(tournamentId, msg.sender, claimableAmount);
    }

    // ============================================================================
    // View Functions
    // ============================================================================

    /**
     * @notice Get complete tournament details
     * @param tournamentId ID of the tournament
     * @return Tournament struct containing all tournament data
     */
    function getTournament(
        uint256 tournamentId
    ) external view returns (Tournament memory) {
        return tournaments[tournamentId];
    }

    /**
     * @notice Check if an address has joined a specific tournament
     * @param tournamentId ID of the tournament
     * @param participant Address to check
     * @return True if the address has joined the tournament, false otherwise
     */
    function hasJoined(
        uint256 tournamentId,
        address participant
    ) external view returns (bool) {
        return participants[tournamentId][participant];
    }

    /**
     * @notice Get the amount already claimed by a participant in a Global tournament
     * @param tournamentId ID of the tournament
     * @param participant Address of the participant
     * @return The amount already claimed by the participant
     */
    function getClaimedAmount(
        uint256 tournamentId,
        address participant
    ) external view returns (uint256) {
        return claimedAmounts[tournamentId][participant];
    }

    // ============================================================================
    // Receive Function
    // ============================================================================

    /**
     * @notice Prevents direct ETH transfers to the contract
     * @dev Users must use joinTournament() to participate
     *      This prevents accidental ETH transfers
     */
    receive() external payable {
        revert("Use joinTournament to participate");
    }
}
