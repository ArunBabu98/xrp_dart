import 'package:xrp_dart/src/xrpl/models/xrp_transactions.dart';

/// Vote on the trading fee for an Automated Market Maker (AMM) instance.
/// Up to 8 accounts can vote in proportion to the amount of the AMM's LP Tokens
/// they hold.
/// Each new vote re-calculates the AMM's trading fee based on a weighted average
/// of the votes.
class AMMVote extends XRPTransaction {
  /// [asset] The definition for one of the assets in the AMM's pool.
  final XRPCurrencies asset;

  /// [asset] The definition for one of the assets in the AMM's pool.
  final XRPCurrencies asset2;

  /// [tradingFee] The proposed fee to vote for, in units of 1/100,000; a value of 1 is equivalent
  /// to 0.001%.
  /// The maximum value is 1000, indicating a 1% fee. This field is required.
  final int tradingFee;

  AMMVote(
      {required String account,
      required this.tradingFee,
      required this.asset,
      required this.asset2,
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
            transactionType: XRPLTransactionType.ammVote);

  AMMVote.fromJson(Map<String, dynamic> json)
      : asset = XRPCurrencies.fromJson(json["asset"]),
        asset2 = XRPCurrencies.fromJson(json["asset2"]),
        tradingFee = json["trading_fee"],
        super.json(json);

  @override
  String? get validate {
    if (tradingFee < 0 || tradingFee > AMMCreate.ammMaxTradingFee) {
      "TradingFee Must be between 0 and ${AMMCreate.ammMaxTradingFee}";
    }
    return super.validate;
  }

  /// Converts the object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      "asset": asset.toJson(),
      "asset2": asset2.toJson(),
      "trading_fee": tradingFee,
      ...super.toJson()
    };
  }
}
