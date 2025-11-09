const { Octokit } = require("@octokit/rest");

/**
 * GitHub Actions Integration Service
 *
 * Provides methods to trigger and monitor GitHub Actions workflows
 * for the Deplight platform deployment pipeline
 */
class GitHubService {
  constructor(token) {
    if (!token) {
      throw new Error('GitHub token is required for GitHubService');
    }

    this.octokit = new Octokit({
      auth: token
    });

    // Default platform repository
    this.platformOwner = 'Softbank-mango';
    this.platformRepo = 'deplight-platform-v3';
    this.workflowFileName = 'deploy.yml';
  }

  /**
   * Trigger a deployment workflow
   * @param {string} targetRepository - Target repository URL to deploy (e.g., "https://github.com/user/repo")
   * @param {string} targetBranch - Branch to deploy (default: "main")
   * @param {string} deploymentId - Unique deployment ID for tracking
   * @returns {Promise<{runId: number, url: string}>}
   */
  async triggerDeployment(targetRepository, targetBranch = 'main', deploymentId = null) {
    try {
      const response = await this.octokit.actions.createWorkflowDispatch({
        owner: this.platformOwner,
        repo: this.platformRepo,
        workflow_id: this.workflowFileName,
        ref: 'main',
        inputs: {
          environment: 'dev',
          target_repository: targetRepository,
          target_branch: targetBranch,
          deployment_id: deploymentId || `deployment-${Date.now()}`
        }
      });

      // Wait briefly for the workflow run to be created
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Get the run ID by fetching recent workflows
      const runs = await this.octokit.actions.listWorkflowRuns({
        owner: this.platformOwner,
        repo: this.platformRepo,
        workflow_id: this.workflowFileName,
        per_page: 5
      });

      // Find the most recent run
      const latestRun = runs.data.workflow_runs[0];

      return {
        runId: latestRun.id,
        url: latestRun.html_url,
        status: latestRun.status,
        conclusion: latestRun.conclusion
      };

    } catch (error) {
      console.error('Error triggering deployment:', error);
      throw new Error(`Failed to trigger deployment: ${error.message}`);
    }
  }

  /**
   * Get workflow run status
   * @param {number} runId - GitHub Actions run ID
   * @returns {Promise<{status: string, conclusion: string, jobs: Array}>}
   */
  async getWorkflowStatus(runId) {
    try {
      const [runResponse, jobsResponse] = await Promise.all([
        this.octokit.actions.getWorkflowRun({
          owner: this.platformOwner,
          repo: this.platformRepo,
          run_id: runId
        }),
        this.octokit.actions.listJobsForWorkflowRun({
          owner: this.platformOwner,
          repo: this.platformRepo,
          run_id: runId
        })
      ]);

      const run = runResponse.data;
      const jobs = jobsResponse.data.jobs;

      return {
        runId: run.id,
        status: run.status, // "queued", "in_progress", "completed"
        conclusion: run.conclusion, // "success", "failure", "cancelled", null
        url: run.html_url,
        createdAt: run.created_at,
        updatedAt: run.updated_at,
        jobs: jobs.map(job => ({
          id: job.id,
          name: job.name,
          status: job.status,
          conclusion: job.conclusion,
          startedAt: job.started_at,
          completedAt: job.completed_at,
          steps: job.steps ? job.steps.map(step => ({
            name: step.name,
            status: step.status,
            conclusion: step.conclusion,
            number: step.number
          })) : []
        }))
      };

    } catch (error) {
      console.error('Error getting workflow status:', error);
      throw new Error(`Failed to get workflow status: ${error.message}`);
    }
  }

  /**
   * Get deployment service information
   * This would query AWS resources to get the deployed service URL and status
   * @param {number} runId - GitHub Actions run ID (used as deployment ID)
   * @returns {Promise<{url: string, status: string, taskStatus: string}>}
   */
  async getDeploymentServiceInfo(runId) {
    // This is a placeholder - in real implementation, this would:
    // 1. Query DynamoDB for deployment logs
    // 2. Query ECS for task status
    // 3. Construct the ALB URL

    const albDns = 'delightful-deploy-alb-500232323.ap-northeast-2.elb.amazonaws.com';
    const serviceUrl = `http://${albDns}/app/${runId}/`;

    return {
      url: serviceUrl,
      deploymentId: runId,
      albDns: albDns,
      // These would be fetched from AWS in real implementation
      status: 'unknown', // Would be from DynamoDB
      taskStatus: 'unknown', // Would be from ECS
      healthStatus: 'unknown' // Would be from ALB health checks
    };
  }

  /**
   * Stream deployment progress
   * Returns an async generator that yields progress updates
   * @param {number} runId - GitHub Actions run ID
   * @param {number} pollInterval - Polling interval in milliseconds (default: 5000)
   */
  async *streamDeploymentProgress(runId, pollInterval = 5000) {
    let previousStatus = null;
    let isComplete = false;

    while (!isComplete) {
      try {
        const status = await this.getWorkflowStatus(runId);

        // Yield update if status changed
        if (JSON.stringify(status) !== JSON.stringify(previousStatus)) {
          yield status;
          previousStatus = status;
        }

        // Check if deployment is complete
        if (status.status === 'completed') {
          // Get final service information
          const serviceInfo = await this.getDeploymentServiceInfo(runId);
          yield {
            ...status,
            serviceInfo
          };
          isComplete = true;
        } else {
          // Wait before next poll
          await new Promise(resolve => setTimeout(resolve, pollInterval));
        }

      } catch (error) {
        console.error('Error streaming deployment progress:', error);
        yield {
          error: true,
          message: error.message
        };
        break;
      }
    }
  }
}

module.exports = GitHubService;
