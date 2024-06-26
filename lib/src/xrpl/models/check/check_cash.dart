import 'package:xrpl_dart/src/xrpl/models/xrp_transactions.dart';
import 'package:xrpl_dart/src/crypto/crypto.dart';

/// Represents a CheckCash transaction [https://xrpl.org/checkcash.html](https://xrpl.org/checkcash.html),
/// which redeems a Check object to receive up to the amount authorized by the
/// corresponding CheckCreate transaction. Only the Destination address of a
/// Check can cash it.
class CheckCash extends XRPTransaction {
  /// [checkId] The ID of the Check ledger object. to cash, as a 64-character
  /// hexadecimal string
  final String checkId;

  /// [amount] Redeem the Check for exactly this amount, if possible. The currency must
  /// match that of the SendMax of the corresponding CheckCreate transaction.
  /// You must provide either this field or DeliverMin.
  final CurrencyAmount? amount;

  /// [deliverMin] Redeem the Check for at least this amount and for as much as possible.
  /// The currency must match that of the SendMax of the corresponding
  /// CheckCreate transaction. You must provide either this field or Amount.
  final CurrencyAmount? deliverMin;

  CheckCash({
    required String account,
    required this.checkId,
    this.amount,
    this.deliverMin,
    List<XRPLMemo>? memos = const [],
    XRPLSignature? signer,
    int? ticketSequance,
    BigInt? fee,
    int? lastLedgerSequence,
    int? sequence,
    List<XRPLSigners>? multisigSigners,
    int? flags,
    int? sourceTag,
  }) : super(
            account: account,
            fee: fee,
            lastLedgerSequence: lastLedgerSequence,
            memos: memos,
            sequence: sequence,
            multisigSigners: multisigSigners,
            sourceTag: sourceTag,
            flags: flags,
            ticketSequance: ticketSequance,
            signer: signer,
            transactionType: XRPLTransactionType.checkCash);

  @override
  String? get validate {
    if (!((amount == null) ^ (deliverMin == null))) {
      return "CheckCash either amount or deliver_min must be set but not both";
    }
    return super.validate;
  }

  /// Converts the object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      "check_id": checkId,
      "amount": amount?.toJson(),
      "deliver_min": deliverMin?.toJson(),
      ...super.toJson()
    };
  }

  CheckCash.fromJson(Map<String, dynamic> json)
      : checkId = json["check_id"],
        amount = json["amount"] == null
            ? null
            : CurrencyAmount.fromJson(json["amount"]),
        deliverMin = json["deliver_min"] == null
            ? null
            : CurrencyAmount.fromJson(json["deliver_min"]),
        super.json(json);
}
