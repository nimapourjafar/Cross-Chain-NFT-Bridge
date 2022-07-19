// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MappedNFTDeployer.sol";
import "./UpgradeableERC721.sol";
import "./interfaces/IEvmSideNFT.sol";
import "./interfaces/ICrossSpaceCall.sol";
import "./interfaces/IConfluxSideNFT.sol";

contract ConfluxSideERC721 is
    IConfluxSideNFT,
    MappedNFTDeployer,
    ReentrancyGuard
{
    ICrossSpaceCall public crossSpaceCall;

    address public override evmSide;

    bool public initialized;

    function initialize(address _evmSide, address _beacon) public {
        require(!initialized, "ConfluxSide: initialized");
        initialized = true;

        evmSide = _evmSide;
        beacon = _beacon;

        // init internal function
        crossSpaceCall = ICrossSpaceCall(
            0x0888000000000000000000000000000000000006
        );

        // set e space cntract to store this contract address
        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(IEvmSideNFT.setCfxSide.selector)
        );

        _transferOwnership(msg.sender);
    }

    function registerMetadata(IERC721Metadata _token) public override {
        require(
            sourceTokens[address(_token)] == address(0),
            "ConfluxSide: token is mapped from evm space"
        );
        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSideNFT.registerCRC721.selector,
                address(_token),
                _token.name(),
                _token.symbol()
            )
        );
    }

    function crossToEvm(
        IERC721 _token,
        address _evmAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        // make sure token is not ERC 20 but CRC20
        require(
            sourceTokens[address(_token)] == address(0),
            "ConfluxSide: token is mapped from evm space"
        );
        require(
            _token.ownerOf(_tokenId) == msg.sender,
            "ConfluxSide: must be owner of token"
        );

        // lock tokens in ConlufxSide contract
        _token.safeTransferFrom(msg.sender, address(this), _tokenId);

        //  call the evm contract to mint the tokens
        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSideNFT.mint.selector,
                address(_token),
                _evmAccount,
                _tokenId
            )
        );

        emit CrossToEvm(address(_token), msg.sender, _evmAccount, _tokenId);
    }

    // withdraw CRC20 locked as ERC20 on EVM space
    function withdrawFromEvm(
        IERC721 _token,
        address _evmAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        require(
            sourceTokens[address(_token)] == address(0),
            "ConfluxSide: token is mapped from evm space"
        );

        // call evm contract to burn the tokens from the sender on e space
        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSideNFT.burn.selector,
                address(_token),
                _evmAccount,
                msg.sender,
                _tokenId
            )
        );

        // transfer the tokens to the sender after burn is successful
        _token.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit WithdrawFromEvm(
            address(_token),
            msg.sender,
            _evmAccount,
            _tokenId
        );
    }

    // add CRC 20 token -> EVM space mapping
    function createMappedToken(address _evmToken) public nonReentrant {
        require(
            mappedTokens[_evmToken] == address(0),
            "ConfluxSide: already created"
        );
        _createMappedToken(_evmToken);
    }

    function _createMappedToken(address _evmToken) internal {
        address t = abi.decode(
            crossSpaceCall.callEVM(
                bytes20(evmSide),
                abi.encodeWithSelector(
                    IMappedTokenDeployer.sourceTokens.selector,
                    _evmToken
                )
            ),
            (address)
        );
        require(
            t == address(0),
            "ConfluxSide: token is mapped from core space"
        );
        (string memory name, string memory symbol) = abi.decode(
            crossSpaceCall.callEVM(
                bytes20(evmSide),
                abi.encodeWithSelector(
                    IEvmSideNFT.getTokenData.selector,
                    _evmToken
                )
            ),
            (string, string)
        );
        _deploy(_evmToken, name, symbol);
    }

    // cross ERC20 from EVM space to CRC20 on Core space
    function crossFromEvm(
        address _evmToken,
        address _evmAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        if (mappedTokens[_evmToken] == address(0)) {
            _createMappedToken(_evmToken);
        }

        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSideNFT.crossToCfx.selector,
                _evmToken,
                _evmAccount,
                msg.sender,
                _tokenId
            )
        );

        UpgradeableERC721(mappedTokens[_evmToken]).safeMint(
            msg.sender,
            _tokenId
        );

        emit CrossFromEvm(_evmToken, msg.sender, _evmAccount, _tokenId);
    }

    // withdraw ERC20 to EVM space from CRC 20 on Core space
    function withdrawToEvm(
        address _evmToken,
        address _evmAccount,
        uint256 _tokenId
    ) public override nonReentrant {
        require(
            mappedTokens[_evmToken] != address(0),
            "ConfluxSide: not mapped token"
        );

        UpgradeableERC721(mappedTokens[_evmToken]).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        UpgradeableERC721(mappedTokens[_evmToken]).burn(_tokenId);

        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSideNFT.withdrawFromCfx.selector,
                _evmToken,
                _evmAccount,
                _tokenId
            )
        );

        emit WithdrawToEvm(_evmToken, msg.sender, _evmAccount, _tokenId);
    }
}
