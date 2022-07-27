// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

contract DocMinter {

    event Received(uint256 value);
    event Minting(uint256 value);
    event Minted(uint256 value);
    event Refunded(uint256 value);

    address payable private mocAddr;
    address private docAddr;
    //address private mocExchangeAddr;
    //address private mocInrateAddr;
    //address private mocVendorAddr; //shree removed to try flow without vendor

    //constructor(address payable _mocAddr, address _docAddr, address _mocExchangeAddr, address _mocInrateAddr, address _mocVendorAddr) {
    constructor(address payable _mocAddr, address _docAddr) {
        mocAddr = _mocAddr;
        docAddr = _docAddr;
        //mocExchangeAddr = _mocExchangeAddr;
        //mocInrateAddr = _mocInrateAddr;
        //mocVendorAddr = _mocVendorAddr;
    }

    receive() external payable {
        emit Received(msg.value);
    }

    // add amount to mint so it is distinct from msg.value
    function mintDoc(address payable receiverAddr, address payable refundAddr, uint256 btcToMint) payable external returns (uint256) {
        emit Minting(btcToMint);

        bool success;
        bytes memory _returnData;

        uint256 oldBalance = address(this).balance - msg.value;

        (success, _returnData) = docAddr.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }
        (uint256 oldDocBalance) = abi.decode(_returnData, (uint256));

        // Is this call needed? Estimating fees is expensive. Could just sending more msg.value (or estimate it off-chain)
        //uint256 fee = _calcCommission(); //todo(shree) what if 0? b/c of MocMarkup. shouldn't be 0 for RBTC

        //(success, _returnData) = mocAddr.call{value: msg.value}(abi.encodeWithSignature("mintDocVendors(uint256,address)", msg.value - fee, mocVendorAddr));
        // no need to use vendor route for simplest use
        (success, _returnData) = mocAddr.call{value: msg.value}(abi.encodeWithSignature("mintDoc(uint256)", btcToMint));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }

        (success, _returnData) = docAddr.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }
        (uint256 docBalance) = abi.decode(_returnData, (uint256));

        uint256 mintedDoc = docBalance - oldDocBalance;
        emit Minted(mintedDoc);

        (success, _returnData) = docAddr.call(abi.encodeWithSignature("transfer(address,uint256)", receiverAddr, mintedDoc));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }

        //  Why? Bcos  msg.value >= btcToMint
        uint256 remainder = address(this).balance - oldBalance;
        if (remainder > 0) {
            (success, ) = refundAddr.call{value: remainder}("");
            require(success, "Failed to send remainder to refundAddr");

            emit Refunded(remainder);
        }

        return mintedDoc;
    }

    // todo(shree) is this needed? I don't think so (unless we are specifying a vendor)
    /*function _calcCommission() internal returns (uint256) {
        bool success;
        bytes memory _returnData;

        // todo(shree) is this needed?
        (success, _returnData) = mocInrateAddr.call(abi.encodeWithSignature("MINT_DOC_FEES_MOC()"));
        require(success, "MINT_DOC_FEES_MOC() failed");
        (uint8 txTypeFeesMOC) = abi.decode(_returnData, (uint8));

        (success, _returnData) = mocInrateAddr.call(abi.encodeWithSignature("MINT_DOC_FEES_RBTC()"));
        require(success, "MINT_DOC_FEES_RBTC() failed");
        (uint8 txTypeFeesRBTC) = abi.decode(_returnData, (uint8));

        // todo(shree) does this need all the args? what are soem dummy values we can send? 
        (success, _returnData) = mocExchangeAddr.call(abi.encodeWithSignature("calculateCommissionsWithPrices((address,uint256,uint8,uint8,address))",
            address(this), msg.value, txTypeFeesMOC, txTypeFeesRBTC, mocVendorAddr));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }

        // (uint256 btcCommission, uint256 mocCommission, uint256 btcPrice, uint256 mocPrice, uint256 btcMarkup, uint256 mocMarkup)
        (uint256 btcCommission, , , , uint256 btcMarkup, uint256 mocMarkup) = abi.decode(_returnData, (uint256, uint256, uint256, uint256, uint256, uint256));

        if (mocMarkup > 0) {
            return 0;
        }

        return btcCommission + btcMarkup;
    }
    */

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

}
