import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Interface, ZeroAddress, FunctionFragment, keccak256, solidityPackedKeccak256 } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

/**
 * Deploys contracts using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  const { diamond } = hre.deployments;

  const ccipDiamond = await diamond.deploy("CCIPDiamond", {
    from: deployer.address,

    autoMine: true,
    log: true,
    waitConfirmations: 1,
    defaultOwnershipFacet: false,
    defaultCutFacet: false,
    diamondContract: "Diamond",

    // diamondContractArgs: [deployer, [], ""],
    // owner: deployer,
    // excludeSelectors: { [""]: [FunctionFragment.getSelector("")] },

    facets: [
      { name: "SharedDiamondInitFacet" },
      { name: "AccessControlFacet" },
      { name: "DiamondCutFacet" },
      { name: "ERC721Facet" },
      { name: "CCIPFacet" },
      { name: "NftMain" },
      { name: "NftCrossChainBurnAndMint" },
      { name: "NftCrossChainMinter" },
      { name: "NftCrossChainReceiver" },
    ],

    execute: {
      contract: "SharedDiamondInitFacet",
      methodName: "init",
      args: [
        "CCNft",
        "CCNFT",
        "ipfs://yourUri",
        ZeroAddress, // router
        ZeroAddress, // link
      ],
    },
  });

  console.log("CCIP Diamond deployed to: ", ccipDiamond.address);
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["YourContract"];
