// SPDX-License-Identifier: UNLICENSED
// Compatible with OpenZeppelin Contracts ^4.9.3

// Solidity version
pragma solidity ^0.8.20;

// Import OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// NFT contract definition
contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // Constants
    uint256 public constant MAX_SUPPLY = 1000; // Maximum total supply of tokens
    uint256 private constant MAX_MINT_AMOUNT = 3; // Maximum number of tokens that can be minted in one transaction
    uint256 private constant PRICE_PER_TOKEN = 0.01 ether; // Price per token in Ether
    uint256 private constant PRICE_PER_SET = 0.02 ether; // Price for minting a complete set of tokens
    uint256 private constant SET_AMOUNT = 6; // Number of tokens in a complete set
    uint256 private constant MAX_PER_WALLET = SET_AMOUNT; // Maximum number of tokens per wallet

    // State variables
    Counters.Counter private _supply; // Counter for tracking the number of tokens minted
    bool private _locked = false; // Flag to prevent re-entrant calls
    mapping(bytes32 => bool) private _usedSignatures; // Mapping to track used signatures

    // Event emitted when a set is minted
    event SetMinted(address indexed _to, uint256[SET_AMOUNT] _tokenIds);

    // Constructor
    constructor() ERC721("MyToken", "MTK") {}

    // Mint function: Allows users to mint tokens
    function mint(uint256 _quantity) external payable reentrantGuard {
        address _to = msg.sender;
        require(_quantity > 0 && _quantity <= MAX_MINT_AMOUNT && (balanceOf(_to) + _quantity) <= MAX_PER_WALLET, "Invalid mint quantity."); // Check mint quantity and wallet limit
        require(msg.value >= (PRICE_PER_TOKEN * _quantity), "Incorrect payment amount."); // Check payment amount

        _mintLoop(_to, _quantity);
    }

    // Mint set function: Allows users to mint a complete set of tokens
    function mintSet() external payable reentrantGuard {
        address _to = msg.sender;
        uint[SET_AMOUNT] memory _tokenIds;

        require(balanceOf(_to) == 0, "You cannot mint set (limit exceeded)."); // Check if the wallet already owns tokens
        require(msg.value >= PRICE_PER_SET, "Incorrect payment amount"); // Check payment amount

        _mintLoop(_to, MAX_MINT_AMOUNT); // Mint the first batch of tokens
        _mintLoop(_to, MAX_MINT_AMOUNT); // Mint the second batch of tokens

        // Generate token IDs for the set
        for (uint256 i = 1; i <= SET_AMOUNT; ++i) {
            _tokenIds[i - 1] = _supply.current() - i;
        }

        emit SetMinted(_to, _tokenIds); // Emit event indicating set minted
    }

    // Signed mint function: Allows owner to mint tokens using a signature
    function signedMint(uint256 _quantity, bytes calldata _signature, bytes32 _nonce) external reentrantGuard {
        address _to = msg.sender;
        bytes32 _messageHash = keccak256(abi.encodePacked(_quantity, _to, _nonce));
        require(!_usedSignatures[_messageHash], "Signature already used"); // Check if signature has been used
        address signer = ECDSA.recover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
                ),
                _signature
        	);
        require(signer == owner(), "Invalid signature"); // Check if signature is from owner
        _usedSignatures[_messageHash] = true; // Mark signature as used
        require(_quantity > 0 && _quantity <= MAX_MINT_AMOUNT && (balanceOf(_to) + _quantity) <= MAX_PER_WALLET, "Invalid mint quantity."); // Check mint quantity and wallet limit
        _mintLoop(_to, _quantity); // Mint tokens
    }

    // Internal function to handle minting loop
    function _mintLoop(address _to, uint256 _quantity) private {
        unchecked {
            require((_quantity + _supply.current()) <= MAX_SUPPLY, "Max supply exceeded."); // Check if max supply exceeded

            for (uint256 i = 0; i < _quantity; ++i) {
                _safeMint(_to, _supply.current()); // Mint token
                _supply.increment(); // Increment token counter
            }
        }
    }

    // Function to get total supply
    function totalSupply() public view returns (uint256) {
        return _supply.current(); // Return total supply
    }

    // Withdraw function for contract owner
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{ value: address(this).balance }(""); // Withdraw contract balance
        require(success, "Failed to withdraw Ether."); // Check if withdrawal was successful
    }

    // Reentrant guard modifier
    modifier reentrantGuard() {
		require(!_locked, "No re-entrant call."); // Check if not in re-entrant call
		_locked = true; // Set re-entrant flag
		_;
		_locked = false; // Reset re-entrant flag
	}
}
