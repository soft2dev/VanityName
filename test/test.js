const { ethers, waffle } = require('hardhat')
const { expect } = require('./shared/expect')

const { vanityNameFixture } = require('./shared/fixtures')

const createFixtureLoader = waffle.createFixtureLoader

const toWei = (n) => ethers.utils.parseUnits(n, 18)

const makeDelay = (ms) => {
  return new Promise(resolve => setTimeout(resolve, ms));
}

describe('VanityName', () => {
  let loadFixture
  let user
  let tokenA
  let vanityName
  let feeCollector

  before('create fixture loader', async () => {
    [owner, user, other] = await ethers.getSigners();
    loadFixture = createFixtureLoader([user])
  })

  beforeEach('deploy fixture', async () => {
    ({ tokenA, vanityName, feeCollector } = await loadFixture(vanityNameFixture))
  })


  describe('registerName', async () => {
    it('should be reverted because sender asked Invalid period', async () => {
      await expect(vanityName.connect(user).registerName("test", toWei('50')))
        .to.be.revertedWith('Invalid period')
    })

    it('should be reverted because sender has insufficient tokens', async () => {
      await expect(vanityName.connect(user).registerName("test", toWei('300')))
        .to.be.revertedWith('Insufficient fund')
    })

    it('should be reverted because sender has insufficient tokens for fee', async () => {
      await tokenA.mint(user.address, toWei('300'))
      await expect(vanityName.connect(user).registerName("test", toWei('300')))
        .to.be.revertedWith('Insufficient fund')
    })

    it('should register name', async () => {
      await tokenA.mint(user.address, toWei('400'))
      await tokenA.connect(user).approve(vanityName.address, toWei('304'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      expect(await tokenA.balanceOf(vanityName.address)).to.eq(toWei('300'))
    })

    it('should be reverted because name already exists', async () => {
      await tokenA.mint(user.address, toWei('700'))
      await tokenA.connect(user).approve(vanityName.address, toWei('708'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      await expect(vanityName.connect(user).registerName("test", toWei('300')))
        .to.be.revertedWith("name already registered")
    })
  })

  describe('withdraw', async () => {
    it('should be reverted because fund is still locked', async () => {
      await tokenA.mint(user.address, toWei('400'))
      await tokenA.connect(user).approve(vanityName.address, toWei('304'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      await expect(vanityName.connect(user).withdraw())
        .to.be.revertedWith("Your fund is still locked")
    })

    it('should withraw the fund', async () => {
      await tokenA.mint(user.address, toWei('400'))
      await tokenA.connect(user).approve(vanityName.address, toWei('304'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      await makeDelay(4000);
      await vanityName.connect(user).withdraw()
      expect(await tokenA.balanceOf(user.address)).to.eq(toWei("396"))
    })
  })

  describe('renewRegistration', async () => {
    it('should be reverted because fund is still locked', async () => {
      await tokenA.mint(user.address, toWei('400'))
      await tokenA.connect(user).approve(vanityName.address, toWei('304'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      await expect(vanityName.connect(user).renewRegistration())
        .to.be.revertedWith("Your fund is still locked")
    })

    it('should be reverted because Insufficient fund', async () => {
      await tokenA.mint(user.address, toWei('400'))
      await tokenA.connect(user).approve(vanityName.address, toWei('304'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      await makeDelay(4000)
      await vanityName.connect(user).withdraw()
      await tokenA.connect(user).approve(vanityName.address, toWei('4'))
      await expect(vanityName.connect(user).renewRegistration())
        .to.be.revertedWith("Invalid period")
    })

    it('should be reverted because Insufficient fund', async () => {
      await tokenA.mint(user.address, toWei('304'))
      await tokenA.connect(user).approve(vanityName.address, toWei('304'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      await makeDelay(4000)
      await expect(vanityName.connect(user).renewRegistration())
        .to.be.revertedWith("Insufficient fund")
    })

    it('should renew registration', async () => {
      await tokenA.mint(user.address, toWei('308'))
      await tokenA.connect(user).approve(vanityName.address, toWei('308'))
      await vanityName.connect(user).registerName("test", toWei('300'))
      await makeDelay(4000)
      await vanityName.connect(user).renewRegistration()
      expect(await tokenA.balanceOf(feeCollector)).to.eq(toWei("8"))
    })
  })

})
