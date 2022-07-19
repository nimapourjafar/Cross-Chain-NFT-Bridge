// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
abstract contract IConfluxSideNFT {
    event CrossToEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256 tokenId
    );

    event CrossFromEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256 tokenId
    );

    event WithdrawFromEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256 tokenId
    );

    event WithdrawToEvm(
        address indexed token,
        address indexed cfxAccount,
        address indexed evmAccount,
        uint256 tokenId
    );

    function evmSide() external view virtual returns (address);

    function registerMetadata(IERC721Metadata _token) public virtual;

    function crossToEvm(
        IERC721 _token,
        address _evmAccount,
        uint256 _tokenId
    ) public virtual;

    function withdrawFromEvm(
        IERC721 _token,
        address _evmAccount,
        uint256 _tokenId
    ) public virtual;

    function crossFromEvm(
        address _evmToken,
        address _evmAccount,
        uint256 _tokenId
    ) public virtual;

    function withdrawToEvm(
        address _evmToken,
        address _evmAccount,
        uint256 _tokenId
    ) public virtual;
}
