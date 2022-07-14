// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interfaces/ICrossSpaceCall.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IEvmSide.sol";
import "./interfaces/IConfluxSide.sol";
import "./libraries/SafeERC20.sol";
import "./utils/ReentrancyGuard.sol";
import "./MappedTokenDeployer.sol";
import "./UpgradeableERC20.sol";

// Deployed on Core
contract ConfluxSide is IConfluxSide, MappedTokenDeployer, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // used for cross chain calls
    ICrossSpaceCall public crossSpaceCall;

    // address of contract on e space
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
            abi.encodeWithSelector(IEvmSide.setCfxSide.selector)
        );

        _transferOwnership(msg.sender);
    }

    // register CRC20 token metadata to evm space
    function registerMetadata(IERC20 _token) public override {
        // make sure token is not ERC 20 but CRC20
        require(
            sourceTokens[address(_token)] == address(0),
            "ConfluxSide: token is mapped from evm space"
        );
        // call the evm contract to register crc20 metadata
        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSide.registerCRC20.selector,
                address(_token),
                _token.name(),
                _token.symbol(),
                _token.decimals()
            )
        );
    }

    // CRC20 to EVM space
    function crossToEvm(
        IERC20 _token,
        address _evmAccount,
        uint256 _amount
    ) public override nonReentrant {
        // make sure token is not ERC 20 but CRC20
        require(
            sourceTokens[address(_token)] == address(0),
            "ConfluxSide: token is mapped from evm space"
        );
        require(_amount > 0, "ConfluxSide: invalid amount");
        
        // lock tokens in ConlufxSide contract
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        //  call the evm contract to mint the tokens
        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSide.mint.selector,
                address(_token),
                _evmAccount,
                _amount
            )
        );

        emit CrossToEvm(address(_token), msg.sender, _evmAccount, _amount);
    }

    // withdraw CRC20 locked as ERC20 on EVM space 
    function withdrawFromEvm(
        IERC20 _token,
        address _evmAccount,
        uint256 _amount
    ) public override nonReentrant {
        require(
            sourceTokens[address(_token)] == address(0),
            "ConfluxSide: token is mapped from evm space"
        );
        require(_amount > 0, "ConfluxSide: invalid amount");

        // call evm contract to burn the tokens from the sender on e space
        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSide.burn.selector,
                address(_token),
                _evmAccount,
                msg.sender,
                _amount
            )
        );

        // transfer the tokens to the sender after burn is successful
        _token.safeTransfer(msg.sender, _amount);

        emit WithdrawFromEvm(address(_token), msg.sender, _evmAccount, _amount);
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
        address t =
            abi.decode(
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
        (string memory name, string memory symbol, uint8 decimals) =
            abi.decode(
                crossSpaceCall.callEVM(
                    bytes20(evmSide),
                    abi.encodeWithSelector(
                        IEvmSide.getTokenData.selector,
                        _evmToken
                    )
                ),
                (string, string, uint8)
            );
        _deploy(_evmToken, name, symbol, decimals);
    }

    // cross ERC20 from EVM space to CRC20 on Core space
    function crossFromEvm(
        address _evmToken,
        address _evmAccount,
        uint256 _amount
    ) public override nonReentrant {
        require(_amount > 0, "ConfluxSide: invalid amount");

        if (mappedTokens[_evmToken] == address(0)) {
            _createMappedToken(_evmToken);
        }

        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSide.crossToCfx.selector,
                _evmToken,
                _evmAccount,
                msg.sender,
                _amount
            )
        );

        UpgradeableERC20(mappedTokens[_evmToken]).mint(msg.sender, _amount);

        emit CrossFromEvm(_evmToken, msg.sender, _evmAccount, _amount);
    }

    // withdraw ERC20 to EVM space from CRC 20 on Core space
    function withdrawToEvm(
        address _evmToken,
        address _evmAccount,
        uint256 _amount
    ) public override nonReentrant {
        require(
            mappedTokens[_evmToken] != address(0),
            "ConfluxSide: not mapped token"
        );
        require(_amount > 0, "ConfluxSide: invalid amount");

        UpgradeableERC20(mappedTokens[_evmToken]).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        UpgradeableERC20(mappedTokens[_evmToken]).burn(_amount);

        crossSpaceCall.callEVM(
            bytes20(evmSide),
            abi.encodeWithSelector(
                IEvmSide.withdrawFromCfx.selector,
                _evmToken,
                _evmAccount,
                _amount
            )
        );

        emit WithdrawToEvm(_evmToken, msg.sender, _evmAccount, _amount);
    }
}
