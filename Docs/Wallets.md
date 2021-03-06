# Export/Import

Fully Noded utilizes a QR code in `json` format for exporting and importing wallets. Currently the only known wallets supporting this QR format are [Specter-Destkop](https://github.com/cryptoadvance/specter-desktop/tree/master/docs) and [Gordion Wallet](https://github.com/BlockchainCommons/FullyNoded-2) (formerly known as Fully Noded 2).

An example multisig wallet export QR for testing:</br></br>
<img src="../Images/wallet_export.png" alt="" width="250"/>

### QR Contents

The QR consists of the following fields:

- `descriptor`: `string`
    - A Bitcoin Core [descriptor](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md), which represents your receive keys, it is up to the wallet software to interpret the descriptor and deduce a second descriptor for your change keys. If the wallet conforms to BIP44/49/84/48/45 then simply replacing `/0/*` with `/1/*` will generate the change (`internal`) descriptor.

- `label`: `string`
    - A user defined label for the wallet.

- `blockheight`: `int`
    - Represents when the wallet was created so that wallets may automatically rescan the blockchain from that point.

`JSON` was chosen as it is universal, the client side software can convert the QR code string to data then pass it directly to a `JSON` decoder, and parse it as a dictionary.

```
{
"descriptor": "wsh(sortedmulti(2,[73756c7f\/48h\/0h\/0h\/2h]tpubDCKxNyM3bLgbEX13Mcd8mYxbVg9ajDkWXMh29hMWBurKfVmBfWAM96QVP3zaUcN51HvkZ3ar4VwP82kC8JZhhux8vFQoJintSpVBwpFvyU3\/0\/*,[f9f62194\/48h\/0h\/0h\/2h]tpubDDp3ZSH1yCwusRppH7zgSxq2t1VEUyXSeEp8E5aFS8m43MknUjiF1bSLo3CGWAxbDyhF1XowA5ukPzyJZjznYk3kYi6oe7QxtX2euvKWsk4\/0\/*,[c98b1535\/48h\/0h\/0h\/2h]tpubDCDi5W4sP6zSnzJeowy8rQDVhBdRARaPhK1axABi8V1661wEPeanpEXj4ZLAUEoikVtoWcyK26TKKJSecSfeKxwHCcRrge9k1ybuiL71z4a\/0\/*))",
"blockheight": 638325,
"label": "Multisig Wallet"
}
```

### Benefits

These QR codes make it extremely easy for any app to import any wallet type unambiguously, directly compatible with Bitcoin Core. For multisig it solves the "problem" of users needing to "save all their public keys" as the descriptor holds all the info required to completely recreate the wallet, with the ability to derive all public keys and redeem scripts.
