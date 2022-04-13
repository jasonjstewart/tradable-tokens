import { 
  Contract, 
  ContractFactory 
} from "ethers"
import { ethers } from "hardhat"

// string memory _propertyId, address _propertyOwner, uint _totalSupply, uint _initialSupply, uint32 _pricePerShare 

const main = async(): Promise<any> => {
  const Token: ContractFactory = await ethers.getContractFactory("Token")
  const token: Contract = await (await Token.deploy("TokenId","0x159A749dF54314005c9E38688c3EFcFb99dBcEA6",5000, 2500, 1, { gasLimit: 8000000 }))
  console.log(token.interface.format('json'))

  await token.deployed()
  console.log(`Token deployed to: ${token.address}`)
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error)
  process.exit(1)
})
