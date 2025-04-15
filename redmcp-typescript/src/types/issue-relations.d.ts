/**
 * Type definitions for Issue Relations
 */

export interface GetIssueRelationsParams {
  issue_id: number;
}

export interface CreateIssueRelationParams {
  issue_id: number;
  target_issue_id: number;
  relation_type: string;
  delay?: number;
}

export interface DeleteIssueRelationParams {
  relation_id: number;
}

export interface AddIssueCommentParams {
  issue_id: number;
  comment: string;
}

export interface SetParentIssueParams {
  issue_id: number;
  parent_issue_id: number;
}

export interface RemoveParentIssueParams {
  issue_id: number;
}

export interface GetChildIssuesParams {
  parent_issue_id: number;
}

export interface CreateSubtaskParams {
  parent_issue_id: number;
  subject: string;
  description?: string;
  tracker_id?: number;
  status_id?: number;
  priority_id?: number;
}
