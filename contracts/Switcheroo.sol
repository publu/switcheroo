pragma solidity ^0.8.20;

import "./IVault.sol";
import "./IERC20.sol";

contract Switcheroo {
    // Define the MAI token interface
    IERC20 mai = IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);

    bool private initialized;
    IVault original;
    IVault upgraded;

    function initialize(address _mai, address _original, address _upgraded) public onlyOwner {
        require(!initialized, "Already initialized");
        mai = IERC20(_mai);
        initialized = true;
        original = IVault(_original);
        upgraded = IVault(_upgraded);
    }

    bool private paused = false;

    function pause() public onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
    }

    function unpause() public onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenInitialized() {
        require(initialized, "Contract is not initialized");
        _;
    }

    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    // Function to migrate vaults from an original to an upgraded contract
    function migrate(uint256 vaultId) public whenInitialized whenNotPaused {
        // Ensure the caller is the owner of the vault

        require(original.ownerOf(vaultId) == msg.sender, "Not the owner of vault");

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