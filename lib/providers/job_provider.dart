import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_constants.dart';
import '../models/skill_model.dart';
import '../models/job/job_image_model.dart';
import '../models/job/job_model.dart';
import '../repositories/job_repository.dart';
import 'auth_provider.dart';

final jobRepositoryProvider = Provider((ref) => JobRepository());

/// Get all skills (categories)
final skillsProvider = FutureProvider<List<SkillModel>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getAllSkills();
});

/// Get skill by ID
final skillProvider = FutureProvider.family<SkillModel?, int>((ref, skillId) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getSkillById(skillId);
});

/// Get available jobs (open) – excludes immediate jobs that have expired and jobs posted by the current user
final availableJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  // Also clean up expired immediate jobs on the fly
  await repo.cancelExpiredImmediateJobs();
  final jobs = await repo.getAvailableJobs();
  if (currentUserId == null) return jobs;
  return jobs.where((job) => job.clientId != currentUserId).toList();
});

/// Get client's jobs
final clientJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getClientJobs(userId);
});

final clientPostedJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final jobs = await ref.watch(clientJobsProvider.future);
  return jobs.where((job) => job.status == AppConstants.jobStatusOpen).toList();
});

final clientPastJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final jobs = await ref.watch(clientJobsProvider.future);
  return jobs
      .where(
        (job) => job.status == AppConstants.jobStatusCompleted ||
            job.status == AppConstants.jobStatusCancelled ||
            job.status == AppConstants.jobStatusDeleted,
      )
      .toList();
});

/// Get jobs by skill
final jobsBySkillProvider = FutureProvider.family<List<JobModel>, int>((ref, skillId) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getJobsBySkill(skillId);
});

/// Get specific job
final jobProvider = FutureProvider.family<JobModel?, String>((ref, jobId) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getJobById(jobId);
});

/// Get job images
final jobImagesProvider = FutureProvider.family<List<JobImageModel>, String>((ref, jobId) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getJobImages(jobId);
});

/// Create job
final createJobProvider = FutureProvider.family<JobModel, ({String title, String description, double budget, String location, int skillId, int? desiredCompletionDays, List<XFile> images, bool isImmediate, DateTime? expiresAt, double? jobLat, double? jobLng})>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');
  
  final repo = ref.watch(jobRepositoryProvider);
  final job = await repo.createJob(
    clientId: userId,
    title: params.title,
    description: params.description,
    budget: params.budget,
    location: params.location,
    skillId: params.skillId,
    desiredCompletionDays: params.desiredCompletionDays,
    isImmediate: params.isImmediate,
    expiresAt: params.expiresAt,
    jobLat: params.jobLat,
    jobLng: params.jobLng,
  );

  for (final image in params.images.take(4)) {
    await repo.addJobImage(jobId: job.id, imageFile: image);
  }
  
  // Refresh client jobs
  ref.invalidate(clientJobsProvider);
  ref.invalidate(clientPostedJobsProvider);
  ref.invalidate(clientPastJobsProvider);
  ref.invalidate(availableJobsProvider);
  ref.invalidate(jobImagesProvider(job.id));
  
  return job;
});

/// Update job
final updateJobProvider = FutureProvider.family<void, ({String jobId, String? title, String? description, String? status})>((ref, params) async {
  final repo = ref.watch(jobRepositoryProvider);
  await repo.updateJob(
    jobId: params.jobId,
    title: params.title,
    description: params.description,
    status: params.status,
  );
  
  // Refresh job data
  ref.invalidate(jobProvider(params.jobId));
  ref.invalidate(clientJobsProvider);
  ref.invalidate(clientPostedJobsProvider);
  ref.invalidate(clientPastJobsProvider);
  ref.invalidate(availableJobsProvider);
});

/// Delete job
final deleteJobProvider = FutureProvider.family<void, String>((ref, jobId) async {
  final repo = ref.watch(jobRepositoryProvider);
  await repo.deleteJob(jobId);
  
  // Refresh jobs list
  ref.invalidate(clientJobsProvider);
  ref.invalidate(clientPostedJobsProvider);
  ref.invalidate(clientPastJobsProvider);
  ref.invalidate(availableJobsProvider);
});
