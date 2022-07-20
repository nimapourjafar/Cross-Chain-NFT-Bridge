// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

abstract contract IConfluxSideNFT {
    event CrossToEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256[] tokenIds
    );

    event CrossFromEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256[] tokenIds
    );

    event WithdrawFromEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256[] tokenIds
    );

    event WithdrawToEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256[] tokenIds
    );

    function evmSide() external view virtual returns (address);

    function registerMetadata(IERC721Metadata _token) public virtual;

    function crossToEvm(
        IERC721 _token,
        address _evmAccount,
        uint256[] calldata _tokenIds
    ) public virtual;

    function withdrawFromEvm(
        IERC721 _token,
        address _evmAccount,
        uint256[] calldata _tokenIds
    ) public virtual;

    function crossFromEvm(
        address _evmToken,
        address _evmAccount,
        uint256[] calldata _tokenIds
    ) public virtual;

    function withdrawToEvm(
        address _evmToken,
        address _evmAccount,
        uint256[] calldata _tokenIds
    ) public virtual;
}
