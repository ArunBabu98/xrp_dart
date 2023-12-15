import 'package:xrp_dart/src/xrpl/models/xrp_transactions.dart';

/// Transaction Flags for an NFTokenCreateOffer Transaction.
class NftTokenCreateOfferFlag implements FlagsInterface {
  // Indicates that the offer is to sell an NFT token.
  static const NftTokenCreateOfferFlag tfSellNftoken =
      NftTokenCreateOfferFlag(0x00000001);

  // The integer value associated with the flag.
  final int value;

  // Constructor for NftTokenCreateOfferFlag.
  const NftTokenCreateOfferFlag(this.value);

  @override
  int get id => value;
}

class NftTokenCreateOfferFlagInterface {
  final bool tfSellNftoken;

  NftTokenCreateOfferFlagInterface(this.tfSellNftoken);
}

/// The NFTokenCreateOffer transaction creates either an offer to buy an
/// NFT the submitting account does not own, or an offer to sell an NFT
/// the submitting account does own.
class NFTokenCreateOffer extends XRPTransaction {
  /// [nftokenId] Identifies the TokenID of the NFToken object that the offer references.
  final String nftokenId;

  /// [amount] The amount must be non-zero, except when this is a sell
  /// offer and the asset is XRP. This would indicate that the current
  /// owner of the token is giving it away free, either to anyone at all,
  /// or to the account identified by the Destination field
  final CurrencyAmount amount;

  /// [owner] Indicates the AccountID of the account that owns the
  /// corresponding NFToken.
  /// If the offer is to buy a token, this field must be present
  /// and it must be different than Account (since an offer to
  /// buy a token one already holds is meaningless).

  /// If the offer is to sell a token, this field must not be
  /// present, as the owner is, implicitly, the same as Account
  /// (since an offer to sell a token one doesn't already hold
  /// is meaningless).
  final String? owner;

  /// [expiration] Indicates the time after which the offer will no longer be valid.
  final int? expiration;

  /// [destination] If present, indicates that this offer may only be
  /// accepted by the specified account. Attempts by other
  /// accounts to accept this offer MUST fail.
  final String? destination;
  NFTokenCreateOffer(
      {required this.nftokenId,
      required this.amount,
      required String account,
      this.owner,
      this.expiration,
      this.destination,
      List<XRPLMemo>? memos = const [],
      String signingPubKey = "",
      int? ticketSequance,
      BigInt? fee,
      int? lastLedgerSequence,
      int? sequence,
      List<XRPLSigners>? signers,
      dynamic flags,
      int? sourceTag,
      List<String> multiSigSigners = const []})
      : super(
            account: account,
            fee: fee,
            lastLedgerSequence: lastLedgerSequence,
            memos: memos,
            sequence: sequence,
            signers: signers,
            sourceTag: sourceTag,
            flags: flags,
            ticketSequance: ticketSequance,
            signingPubKey: signingPubKey,
            multiSigSigners: multiSigSigners,
            transactionType: XRPLTransactionType.nftokenCreateOffer);
  @override
  String? get validate {
    if (destination == account) {
      return "destination Must not be equal to the account";
    }
    return super.validate;
  }

  /// Converts the object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      "nftoken_id": nftokenId,
      "amount": amount.toJson(),
      "owner": owner,
      "expiration": expiration,
      "destination": destination,
      ...super.toJson()
    };
  }

  NFTokenCreateOffer.fromJson(Map<String, dynamic> json)
      : nftokenId = json["nftoken_id"],
        amount = CurrencyAmount.fromJson(json["amount"]),
        owner = json["owner"],
        expiration = json["expiration"],
        destination = json["destination"],
        super.json(json);
}
