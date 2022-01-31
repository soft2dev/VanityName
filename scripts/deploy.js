const { ethers, upgrades } = require('hardhat')

async function main() {
  const feeCollector = "0x24e37Dc08cAFbbF698449B28bB4B2805B99e166D";
  const tokenFactory = await ethers.getContractFactory('ERC20Token')
  console.log('Deploying tokens...')
  const tokenA = await tokenFactory.deploy('ERC20 Token A', 'TokenA')
  console.log('TokenA deployed to: ', tokenA.address)

  console.log('Deploying VanityName...')
  const VanityNameFactory = await ethers.getContractFactory('VanityName')
  const vanityName = await upgrades.deployProxy(VanityNameFactory, [tokenA.address, feeCollector], {
    initializer: '__VanityName_init'
  })
  console.log('VanityName deployed to: ', vanityName.address)

  console.log('Successfully deployed!')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})