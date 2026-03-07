/// Precondition for write operations to prevent data loss.
sealed class WritePrecondition {
  const WritePrecondition();
}

final class NoPrecondition extends WritePrecondition {
  const NoPrecondition();
}

final class MustNotExist extends WritePrecondition {
  const MustNotExist();
}

final class MustMatchHash extends WritePrecondition {
  final String expectedHash;
  const MustMatchHash(this.expectedHash);
}
