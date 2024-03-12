pragma solidity ^0.8.20;

interface IVault {
    function ownerOf(uint256 vaultId) external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 vaultId) external;
    function vaultDebt(uint256 vaultId) external view returns (uint256);
    function approve(address to, uint256 amount) external;
    function paybackToken(uint256 vaultId, uint256 amount) external;
    function vaultCollateral(uint256 vaultId) external view returns (uint256);
    function withdrawCollateral(uint256 vaultId, uint256 amount) external;
    function createVault() external returns (uint256);
    function depositCollateral(uint256 vaultId, uint256 amount) external;
    function borrowToken(uint256 vaultId, uint256 amount) external;
}