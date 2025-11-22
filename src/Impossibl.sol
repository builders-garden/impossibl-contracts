// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImpossiblProtocol is Ownable {
    using MerkleProof for bytes32[];

    enum TournamentType {
        Global,
        Group
    }

    enum TournamentStatus {
        Active,
        Completed
    }

    struct Tournament {
        uint256 id;
        TournamentType tournamentType;
        TournamentStatus status;
        address buyInToken; // address(0) for ETH, otherwise ERC20 token address
        uint256 buyInAmount;
        uint256 prizePool;
        address creator;
        uint256 createdAt;
        // For Group tournaments
        address winner; // Single winner address
        // For Global tournaments
        bytes32 merkleRoot; // Merkle root of winners
    }

    // Mapping from tournament ID to tournament
    mapping(uint256 => Tournament) public tournaments;

    // Mapping from tournament ID to participant addresses
    mapping(uint256 => mapping(address => bool)) public participants;

    // Mapping from tournament ID to claimed amounts (for global tournaments)
    mapping(uint256 => mapping(address => uint256)) public claimedAmounts;

    // Counter for tournament IDs
    uint256 public nextTournamentId;

    // Events
    event TournamentCreated(
        uint256 indexed tournamentId,
        TournamentType tournamentType,
        address indexed creator,
        address buyInToken,
        uint256 buyInAmount
    );

    event TournamentJoined(
        uint256 indexed tournamentId,
        address indexed participant,
        uint256 amount
    );

    event GroupWinnerSet(
        uint256 indexed tournamentId,
        address indexed winner,
        uint256 prizeAmount
    );

    event GlobalMerkleRootSet(
        uint256 indexed tournamentId,
        bytes32 merkleRoot
    );

    event PrizeClaimed(
        uint256 indexed tournamentId,
        address indexed winner,
        uint256 amount
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Create a global tournament
     * @param buyInToken Address of the ERC20 token for buy-in (address(0) for ETH)
     * @param buyInAmount Amount required to join the tournament
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
     * @notice Create a group tournament
     * @param buyInToken Address of the ERC20 token for buy-in (address(0) for ETH)
     * @param buyInAmount Amount required to join the tournament
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

    /**
     * @notice Join a tournament by paying the buy-in
     * @param tournamentId ID of the tournament to join
     * @param player Address of the player to register (payment is from msg.sender)
     */
    function joinTournament(uint256 tournamentId, address player) external payable {
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

    /**
     * @notice Set the winner for a group tournament (admin only)
     * @param tournamentId ID of the group tournament
     * @param winner Address of the winner
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
     * @notice Set the merkle root for a global tournament (admin only)
     * @param tournamentId ID of the global tournament
     * @param merkleRoot Merkle root containing winner information
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

    /**
     * @notice Claim prize for a global tournament using merkle proof
     * @param tournamentId ID of the global tournament
     * @param amount Amount to claim
     * @param proof Merkle proof for the claim
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

    /**
     * @notice Get tournament details
     * @param tournamentId ID of the tournament
     */
    function getTournament(
        uint256 tournamentId
    ) external view returns (Tournament memory) {
        return tournaments[tournamentId];
    }

    /**
     * @notice Check if an address has joined a tournament
     * @param tournamentId ID of the tournament
     * @param participant Address to check
     */
    function hasJoined(
        uint256 tournamentId,
        address participant
    ) external view returns (bool) {
        return participants[tournamentId][participant];
    }

    /**
     * @notice Get claimed amount for a participant in a global tournament
     * @param tournamentId ID of the tournament
     * @param participant Address of the participant
     */
    function getClaimedAmount(
        uint256 tournamentId,
        address participant
    ) external view returns (uint256) {
        return claimedAmounts[tournamentId][participant];
    }

    // Receive ETH
    receive() external payable {
        revert("Use joinTournament to participate");
    }
}

