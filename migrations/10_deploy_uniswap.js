module.exports = async function(deployer) {
    await deployer.deploy(artifacts.require("ConnectUniswapV2"));
    var connectersInstance = await artifacts.require("InstaConnectors").deployed();
    await connectersInstance.enable(artifacts.require("ConnectUniswapV2").address)
};
