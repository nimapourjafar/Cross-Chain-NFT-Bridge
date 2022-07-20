// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interfaces/IEvmSideNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./MappedNFTDeployer.sol";
import "./UpgradeableERC721.sol";

contract EvmSide is IEvmSideNFT, MappedNFTDeployer, ReentrancyGuard {
    address public override cfxSide;

    mapping(address => TokenMetadata) public crc721Metadata;

    mapping(address => mapping(address => mapping(address => uint256)))
        public
        override lockedMappedToken;

    mapping(address => mapping(address => mapping(address => uint256)))
        public
        override lockedToken;

    bool public initialized;

    function setCfxSide() public override {
        require(cfxSide == address(0), "EvmSide: cfx side set already");
        cfxSide = msg.sender;
    }

    function initialize(address _beacon) public {
        require(!initialized, "EvmSide: initialized");
        initialized = true;

        beacon = _beacon;

        _transferOwnership(msg.sender);
    }

    function getTokenData(address _token)
        public
        view
        override
        returns (string memory, string memory)
    {
        return (IERC721Metadata(_token).name(), IERC721Metadata(_token).symbol());
    }

    // register token from core metadata to e space
    function registerCRC721(
        address _crc721,
        string memory _name,
        string memory _symbol
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        require(!crc721Metadata[_crc721].registered, "EvmSide: registered");
        TokenMetadata memory d;
        d.name = _name;
        d.symbol = _symbol;
        d.registered = true;

        crc721Metadata[_crc721] = d;
    }

    function createMappedToken(address _crc721) public override {
        require(crc721Metadata[_crc721].registered, "EvmSide: not registered");
        TokenMetadata memory d = crc721Metadata[_crc721];
        _deploy(_crc721, d.name, d.symbol);
    }

    function mint(
        address _token,
        address _to,
        uint256 _tokenId
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        // make sure token exists on e space
        require(
            mappedTokens[_token] != address(0),
            "EvmSide: token is not mapped"
        );
        // mint token on espace
        UpgradeableERC721(mappedTokens[_token]).safeMint(_to, _tokenId);
    }

    function burn(
        address _token,
        address _evmAccount,
        address _cfxAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        require(
            mappedTokens[_token] != address(0),
            "EvmSide: token is not mapped"
        );
        address mappedToken = mappedTokens[_token];
        // check if the ERC 20 tokens locked on EVM side are enough to burn for core space
        uint256 userLockedToken = lockedMappedToken[mappedToken][_evmAccount][
            _cfxAccount
        ];
        require(userLockedToken == _tokenId, "EvmSide: insufficent lock");
        // burn token on espace
        UpgradeableERC721(mappedToken).burn(userLockedToken);
        // update locked balance
        lockedMappedToken[mappedToken][_evmAccount][_cfxAccount] = 0;

        emit LockedMappedToken(mappedToken, _evmAccount, _cfxAccount, 0);
    }

    // lock mapped CRC20 for a conflux space address
    function lockMappedToken(
        address _mappedToken,
        address _cfxAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        require(
            sourceTokens[_mappedToken] != address(0),
            "EvmSide: not mapped token"
        );
        // checks how much is currently locked
        uint256 oldToken = lockedMappedToken[_mappedToken][msg.sender][
            _cfxAccount
        ];
        // refunds the old amount if there is any
        if (oldToken != 0) {
            UpgradeableERC721(_mappedToken).safeTransferFrom(
                address(this),
                msg.sender,
                oldToken
            );
        }
        // locks the new amount
        UpgradeableERC721(_mappedToken).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        lockedMappedToken[_mappedToken][msg.sender][_cfxAccount] = _tokenId;

        emit LockedMappedToken(_mappedToken, msg.sender, _cfxAccount, _tokenId);
    }

    // lock ERC20 for a conflux space address
    function lockToken(
        IERC721 _token,
        address _cfxAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        require(
            sourceTokens[address(_token)] == address(0),
            "EvmSide: token is mapped from core space"
        );

        uint256 oldToken = lockedToken[address(_token)][msg.sender][
            _cfxAccount
        ];
        if (oldToken != 0) {
            _token.safeTransferFrom(address(this), msg.sender, oldToken);
        }

        _token.safeTransferFrom(msg.sender, address(this), _tokenId);
        lockedToken[address(_token)][msg.sender][_cfxAccount] = _tokenId;

        emit LockedToken(address(_token), msg.sender, _cfxAccount, _tokenId);
    }

    // cross ERC20 to conflux space
    function crossToCfx(
        address _token,
        address _evmAccount,
        address _cfxAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        uint256 userLockedToken = lockedToken[_token][_evmAccount][_cfxAccount];
        require(userLockedToken == _tokenId, "EvmSide: not your token");
        lockedToken[_token][_evmAccount][_cfxAccount] = 0;

        emit LockedToken(_token, _evmAccount, _cfxAccount, 0);
    }

    // withdraw from conflux space
    function withdrawFromCfx(
        address _token,
        address _evmAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        IERC721(_token).safeTransferFrom(address(this), _evmAccount, _tokenId);
    }

    /// @notice Accept ERC721 tokens
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        // IERC721.onERC721Received.selector
        return 0x150b7a02;
    }
}
