enum FormSubmissionStatus { idle, submitting, success, failure }

extension FormSubmissionStatusX on FormSubmissionStatus {
  bool get isSubmitting => this == FormSubmissionStatus.submitting;
  bool get isFailure => this == FormSubmissionStatus.failure;
  bool get isSuccess => this == FormSubmissionStatus.success;
}
