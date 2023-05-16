const dateString = new Date()
  .toISOString()
  .substring(0, 16)
  .replace(/[^0-9]+/g, "");
const composeNetworkName = `fablo_network_${dateString}`;

export { composeNetworkName };

