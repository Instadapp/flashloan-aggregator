const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre


import {
    AaveImplementation,
    BalancerImplementation,
    MakerImplementation,
    AaveImplementation__factory,
    BalancerImplementation__factory,
    MakerImplementation__factory,
    InstaFlashAggregator,
    InstaFlashAggregator__factory,
    IERC20__factory,
    IERC20,
    InstaFlashReceiver__factory,
    InstaFlashReceiver,
    InstaFlashAggregatorProxy,
    InstaFlashAggregatorProxy__factory,
  } from '../../typechain'
  
  describe('FlashLoan', function () {

    let proxyA : AaveImplementation,
     proxyB : BalancerImplementation,
     proxyM : MakerImplementation,
     aggregator : InstaFlashAggregator,
     ProxyA,
     ProxyB,
     ProxyM,
     Aggregator,
     admin = "0xb208CDF8e1c319d0019397dceC8E0bA3Fb9A149F",
     proxyAddr = "0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882",
     proxyCon: { connect: (arg0: any) => { (): any; new(): any; upgradeTo: { (arg0: string): any; new(): any }; callStatic: { (): any; new(): any; implementation: { (): any; new(): any } } }; initialize: (arg0: string, arg1: string, arg2: string) => any },
     Receiver,
     receiver: InstaFlashReceiver

    let signer: SignerWithAddress

    const _data = '0x'
    let _instaData = '0x'

//##############
    const Dai = ethers.utils.parseUnits('5000', 18)

//##############
    const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'
    const ACC_DAI = '0x9a7a9d980ed6239b89232c012e21f4c210f4bef1'


    it('Should deploy', async function () {
        ;[signer] = await ethers.getSigners()

        ProxyA = new AaveImplementation__factory
        proxyA = await ProxyA.deploy()
        await proxyA.deployed()
        console.log("Aave proxy deployed at: ", proxyA.address);

        ProxyB = new BalancerImplementation__factory
        proxyB = await ProxyB.deploy()
        await proxyB.deployed()
        console.log("Balancer proxy deployed at: ", proxyB.address);

        ProxyM = new MakerImplementation__factory
        proxyM = await ProxyM.deploy()
        await proxyM.deployed()
        console.log("Maker proxy deployed at: ", proxyM.address);

        Aggregator = new InstaFlashAggregator__factory(signer)
        aggregator = await Aggregator.deploy()
        await aggregator.deployed()
        console.log("Aggregator deployed at: ", aggregator.address);

        proxyCon = new hre.ethers.Contract(
            proxyAddr,
            [{"inputs":[{"internalType":"address","name":"_logic","type":"address"},{"internalType":"address","name":"admin_","type":"address"},{"internalType":"bytes","name":"_data","type":"bytes"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"admin_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"implementation_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}]
        )

        Receiver = new InstaFlashReceiver__factory(signer)
        receiver = await Receiver.deploy(proxyAddr)
        await receiver.deployed()
        console.log("Receiver deployed at: ", receiver.address);
      
        const token_dai = new ethers.Contract(
        DAI,
        IERC20__factory.abi,
        ethers.provider,
        )

        await hre.network.provider.send('hardhat_setBalance', [
            ACC_DAI,
            ethers.utils.parseEther('10.0').toHexString(),
        ])
    })

    describe('Upgrade proxy implementation', async function () {
        await hre.network.provider.request({
            method: 'hardhat_impersonateAccount',
            params: [admin],
          })
      
        await hre.network.provider.send("hardhat_setBalance", [
        admin,
        ethers.utils.parseEther("10.0").toHexString(),
        ]);
    
        let impersonateAcc = await ethers.getSigner(admin);
    
        let tx = await proxyCon.connect(impersonateAcc).upgradeTo(aggregator.address);
        let receipt = tx.wait();
        console.log("Implementation updated!")
    
        let addr = await proxyCon.connect(impersonateAcc).callStatic.implementation();
        console.log("Implementation at: ", addr);
        
        await proxyCon.initialize(proxyA.address, proxyB.address, proxyM.address);//todo: doubt
    })

    describe('Single token', async function () {
        it('Should be able to take flashLoan of a single token from AAVE', async function () {
          await receiver.flashBorrow([DAI], [Dai], 1, _data, _instaData)
        })
    })
  })
  