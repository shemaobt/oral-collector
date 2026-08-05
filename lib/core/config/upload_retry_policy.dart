/// How many attempts a recording upload gets before the row is retired.
///
/// Shared rather than owned by either side, because two layers read it and they
/// have to agree: the sync engine refuses a row that has spent the budget, and
/// the local repository writes the terminal status on the attempt that spends
/// it. A private copy on either side is how a row ends up queued by one and
/// refused by the other (ENG-377).
const int kMaxUploadRetries = 5;
