// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

uint8 constant DECIMALS = 18;
uint8 constant DECIMALS_OFFSET = 0;

contract Vault is ERC4626 {
    constructor(IERC20 asset_) ERC4626(asset_) ERC20("vault", "VAULT") {}

    function _decimalsOffset() internal view virtual override returns (uint8) {
        return DECIMALS_OFFSET;
    }
}

contract Token is ERC20 {
    constructor() ERC20("test", "TEST") {}

    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }

    function mint(address dst, uint256 amount) external {
        _mint(dst, amount);
    }

    function burn(address src, uint256 amount) external {
        _burn(src, amount);
    }
}

// forge test --match-path test/OZ_ERC4626.test.sol -vvv
contract OzVaultTest is Test {
    Vault private vault;
    Token private token;

    address[] private users = [address(11), address(12)];

    function setUp() public {
        token = new Token();
        vault = new Vault(IERC20(address(token)));

        for (uint256 i = 0; i < users.length; i++) {
            token.mint(users[i], 1000 * (10 ** DECIMALS));
            vm.prank(users[i]);
            token.approve(address(vault), type(uint256).max);
        }
    }

    function print() private {
        console2.log("vault total supply", vault.totalSupply());
        console2.log("vault balance", token.balanceOf(address(vault)));
        uint256 shares0 = vault.balanceOf(users[0]);
        uint256 shares1 = vault.balanceOf(users[1]);
        console2.log("users[0] shares", shares0);
        console2.log("users[1] shares", shares1);
        console2.log("users[0] redeemable assets", vault.previewRedeem(shares0));
        console2.log("users[1] redeemable assets", vault.previewRedeem(shares1));
    }

    function test() public {
        // users[0] deposit 1
        console2.log("--- users[0] deposit ---");
        vm.prank(users[0]);
        vault.deposit(1, users[0]);
        print();

        // users[0] donate 100
        console2.log("--- users[0] donate ---");
        vm.prank(users[0]);
        token.transfer(address(vault), 100 * (10 ** DECIMALS));
        print();

        // users[1] deposit 100
        console2.log("--- users[1] deposit ---");
        vm.prank(users[1]);
        vault.deposit(100 * (10 ** DECIMALS), users[1]);
        print();
    }
}
