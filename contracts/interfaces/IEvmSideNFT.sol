// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract IEvmSideNFT {
    struct TokenMetadata {
        string name;
        string symbol;
        bool registered;
    }

    event LockedMappedToken(
        address indexed mappedToken,
        address indexed evmAccount,
        address indexed cfxAccount,
        uint256 tokenId
    );

    event LockedToken(
        address indexed token,
        address indexed evmAccount,
        address indexed cfxAccount,
        uint256 tokenId
    );

    function cfxSide() external view virtual returns (address);

    function setCfxSide() public virtual;

    function getTokenData(address _token)
        public
        view
        virtual
        returns (
            string memory,
            string memory
        );

    function lockedMappedToken(
        address _token,
        address _evmAccount,
        address _cfxAccount
    ) external view virtual returns (uint256);

    function lockedToken(
        address _token,
        address _evmAccount,
        address _cfxAccount
    ) external view virtual returns (uint256);

    function registerCRC721(
        address _crc721,
        string memory _name,
        string memory _symbol
    ) public virtual;

    function createMappedToken(address _crc721) public virtual;

    function mint(
        address _token,
        address _to,
        uint256 _tokenId
    ) public virtual;

    function burn(
        address _token,
        address _evmAccount,
        address _cfxAccount,
        uint256 _tokenId
    ) public virtual;

    function lockMappedToken(
        address _mappedToken,
        address _cfxAccount,
        uint256 _tokenId
    ) public virtual;

    function lockToken(
        IERC721 _token,
        address _cfxAccount,
        uint256 _tokenId
    ) public virtual;

    function crossToCfx(
        address _token,
        address _evmAccount,
        address _cfxAccount,
        uint256 _tokenId
    ) public virtual;

    function withdrawFromCfx(
        address _token,
        address _evmAccount,
        uint256 _tokenId
    ) public virtual;
}
