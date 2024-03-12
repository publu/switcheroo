pragma solidity ^0.8.20;

import "./IVault.sol";
import "./IERC20.sol";

contract Switcheroo {
    // Define the MAI token interface
    IERC20 mai = IERC20(0x0);
    
    // Function to migrate vaults from an original to an upgraded contract
    function migrate(address _original, address _upgraded, uint256 vaultId) public {
        // Ensure the caller is the owner of the vault
        require(IVault(_original).ownerOf(vaultId) == msg.sender, "Not the owner of vault");

        // Initialize the original and upgraded vault contracts
        IVault original = IVault(_original);
        IVault upgraded = IVault(_upgraded);
        // Store the initial MAI balance of this contract
        uint256 initial = mai.balanceOf(address(this));

        // Transfer the vault from the user to this contract
        original.safeTransferFrom(msg.sender, address(this), vaultId);

        // Retrieve the debt associated with the vault
        uint256 debt = original.vaultDebt(vaultId);

        // Approve the original contract to spend MAI tokens equal to the debt
        mai.approve(address(original), debt);
        // Pay back the debt of the vault
        original.paybackToken(vaultId, debt);
        
        // Retrieve the collateral amount of the vault
        uint256 collateral = original.vaultCollateral(vaultId);

        // Withdraw the collateral from the original vault to this contract
        original.withdrawCollateral(vaultId, collateral);

        // Create a new vault in the upgraded contract
        uint256 newVaultId = upgraded.createVault();

        // Approve the upgraded contract to spend the collateral
        mai.approve(address(upgraded), collateral);

        // Deposit the collateral into the new vault
        upgraded.depositCollateral(newVaultId, collateral);

        // Borrow the same amount of debt in the new vault
        upgraded.borrowToken(newVaultId, debt);
        // Store the MAI balance after operations
        uint256 later = mai.balanceOf(address(this));

        // Transfer the new vault back to the user
        upgraded.safeTransferFrom(address(this), msg.sender, newVaultId);
        // Ensure the final MAI balance is not less than the initial balance
        require(later >= initial, "Error. Did not end up with enough mai");
    }
}