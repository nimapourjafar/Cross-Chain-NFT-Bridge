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

    mapping(address => mapping(address => mapping(address =>  uint256[] )))
        public
         lockedMappedTokens;

    mapping(address => mapping(address => mapping(address => uint256[])))
        public
         lockedTokens;

    bool public initialized;

    function lockedMappedToken(
        address _token,
        address _evmAccount,
        address _cfxAccount
    ) public view override returns (uint256[] memory){
         uint256[] memory array = lockedMappedTokens[_token][_evmAccount][_cfxAccount];

        return array;
    }

    function lockedToken(
        address _token,
        address _evmAccount,
        address _cfxAccount
    ) public view override returns (uint256[] memory){

        uint256[] memory array = lockedTokens[_token][_evmAccount][_cfxAccount];

        return array;
    }

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
        return (
            IERC721Metadata(_token).name(),
            IERC721Metadata(_token).symbol()
        );
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
        uint256[] calldata _tokenIds
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        // make sure token exists on e space
        require(
            mappedTokens[_token] != address(0),
            "EvmSide: token is not mapped"
        );
        // mint token on espace
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            UpgradeableERC721(mappedTokens[_token]).safeMint(_to, _tokenIds[i]);
        }
    }

    function burn(
        address _token,
        address _evmAccount,
        address _cfxAccount,
        uint256[] memory _tokenIds
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        require(
            mappedTokens[_token] != address(0),
            "EvmSide: token is not mapped"
        );
        address mappedToken = mappedTokens[_token];
        // check if the ERC 20 tokens locked on EVM side are enough to burn for core space
        uint256[] memory userLockedToken = lockedMappedToken(mappedToken,
            _evmAccount
        ,_cfxAccount);
        require(arraysEqual(userLockedToken,_tokenIds),"EvmSide: not your tokens");

        // burn token on espace
        for (uint256 i = 0; i < userLockedToken.length; i++) {
            UpgradeableERC721(mappedToken).burn(userLockedToken[i]);
        }
        // update locked balance
        uint256[] memory emptyArray = new uint256[](0);
        lockedMappedTokens[mappedToken][_evmAccount][_cfxAccount] = emptyArray;

        emit LockedMappedToken(mappedToken, _evmAccount, _cfxAccount, emptyArray);
    }

    // lock mapped CRC20 for a conflux space address
    function lockMappedToken(
        address _mappedToken,
        address _cfxAccount,
        uint256[] memory _tokenIds
    ) public override nonReentrant {
        require(
            sourceTokens[_mappedToken] != address(0),
            "EvmSide: not mapped token"
        );
        // checks how much is currently locked
        uint256[] memory oldToken = lockedMappedToken(_mappedToken,msg.sender,
          _cfxAccount
        );
        // refunds the old amount if there is any

        if (!(arraysEqual(oldToken,new uint256[](0)))) {
            for (uint256 i = 0; i < oldToken.length; i++) {
                UpgradeableERC721(_mappedToken).safeTransferFrom(
                    address(this),
                    msg.sender,
                    oldToken[i]
                );
            }
        }
        // locks the new amount

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            UpgradeableERC721(_mappedToken).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }

        lockedMappedTokens[_mappedToken][msg.sender][_cfxAccount] = _tokenIds;

        emit LockedMappedToken(
            _mappedToken,
            msg.sender,
            _cfxAccount,
            _tokenIds
        );
    }

    // lock ERC20 for a conflux space address
    function lockToken(
        IERC721 _token,
        address _cfxAccount,
        uint256[] memory _tokenIds
    ) public override nonReentrant {
        require(
            sourceTokens[address(_token)] == address(0),
            "EvmSide: token is mapped from core space"
        );

        uint256[] memory oldToken = lockedToken(address(_token),msg.sender
         ,   _cfxAccount
        );
        if (!arraysEqual(oldToken, new uint256[](0))) {
            for (uint256 i = 0; i < oldToken.length; i++) {
                _token.safeTransferFrom(address(this), msg.sender, oldToken[i]);
            }
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _token.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        lockedTokens[address(_token)][msg.sender][_cfxAccount] = _tokenIds;

        emit LockedToken(address(_token), msg.sender, _cfxAccount, _tokenIds);
    }

    // cross ERC20 to conflux space
    function crossToCfx(
        address _token,
        address _evmAccount,
        address _cfxAccount,
        uint256[] memory _tokenIds
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");
        uint256[] memory userLockedToken = lockedToken(_token,_evmAccount
            ,_cfxAccount
        );
        require(arraysEqual(_tokenIds, userLockedToken),"EvmSide: not your tokens");
        lockedTokens[_token][_evmAccount][_cfxAccount] = new uint256[](0);

        emit LockedToken(_token, _evmAccount, _cfxAccount, new uint256[](0));
    }

    // withdraw from conflux space
    function withdrawFromCfx(
        address _token,
        address _evmAccount,
        uint256[] memory _tokenIds
    ) public override nonReentrant {
        require(msg.sender == cfxSide, "EvmSide: sender is not cfx side");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_token).safeTransferFrom(
                address(this),
                _evmAccount,
                _tokenIds[i]
            );
        }
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

    function arraysEqual(uint256[] memory arr1, uint256[] memory arr2)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(arr1)) == keccak256(abi.encodePacked(arr2));
    }


}
