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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Switcheroo {
    IERC20 mai = 0x0;
    
    function migrate(address _original, uint256 vaultId) public {
        require(original.ownerOf(vaultId) == msg.sender, "Not the owner of vault");

        IVault original = IVault(_original);
        IVault upgraded = IVault(_upgraded);
        uint256 initial = mai.balanceOf(address(this));

        original.safeTransferFrom(msg.sender, address(this), vaultId);

        uint256 debt = original.vaultDebt(vaultId);

        mai.approve(address(original), debt);
        original.paybackToken(vaultId, debt); // should payback all debt.
        
        uint256 collateral = original.vaultCollateral(vaultId);
        original.withdrawCollateral(vaultId, collateral);

        uint256 newVaultId = upgraded.createVault();

        collateral.approve(address(upgraded), debt);

        upgraded.depositCollateral(newVaultId, collateral);

        upgraded.borrowToken(newVaultId, debt);
        uint256 final = mai.balanceOf(address(this));
        require(final>=initial, "Error. Did not end up with enough mai");
    }
}