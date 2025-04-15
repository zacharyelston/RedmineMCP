/**
 * Type definitions for Issue Tools
 */

export interface ListIssuesParams {
  project_id?: string | number;
  status_id?: string | number;
  tracker_id?: number;
  limit?: number;
  offset?: number;
  sort?: string;
}

export interface GetIssueParams {
  issue_id: number;
  include?: string[];
}

export interface CreateIssueParams {
  project_id: number;
  subject: string;
  description?: string;
  tracker_id?: number;
  status_id?: number;
  priority_id?: number;
  assigned_to_id?: number;
  parent_issue_id?: number;
}

export interface UpdateIssueParams {
  issue_id: number;
  subject?: string;
  description?: string;
  status_id?: number;
  priority_id?: number;
  assigned_to_id?: number;
  parent_issue_id?: number;
}
