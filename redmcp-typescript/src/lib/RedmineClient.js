"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedmineClient = void 0;
/**
 * RedmineClient - A client for interacting with Redmine API
 *
 * FIXED VERSION FOR ISSUE #76 - Subproject Creation Failure
 */
var axios_1 = __importDefault(require("axios"));
var fs = __importStar(require("fs"));
var path = __importStar(require("path"));
var RedmineClient = /** @class */ (function () {
    /**
     * Create a new Redmine API client
     * @param baseUrl - The base URL of the Redmine instance
     * @param apiKey - API key for authentication
     * @param todoFilePath - Path to the todo.yaml file for error logging
     */
    function RedmineClient(baseUrl, apiKey, todoFilePath) {
        if (todoFilePath === void 0) { todoFilePath = '../../todo.yaml'; }
        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
        this.todoFilePath = path.resolve(__dirname, todoFilePath);
        // Create axios instance with default configuration
        this.api = axios_1.default.create({
            baseURL: baseUrl,
            headers: {
                'X-Redmine-API-Key': apiKey,
                'Content-Type': 'application/json',
                // Accept multiple formats including XML
                'Accept': 'application/json, application/xml, text/xml, */*'
            }
        });
        // Add logging interceptor
        this.api.interceptors.request.use(function (config) {
            var _a;
            // Ensure params object exists
            if (!config.params) {
                config.params = {};
            }
            // Add format=json parameter to all requests
            config.params.format = 'json';
            console.error("Making ".concat((_a = config.method) === null || _a === void 0 ? void 0 : _a.toUpperCase(), " request to ").concat(config.url));
            return config;
        });
        console.error("Initialized Redmine client for ".concat(baseUrl));
    }
    /**
     * Log error to the todo.yaml file
     * @param errorInfo - Error information to log
     */
    RedmineClient.prototype.logError = function (errorInfo) {
        return __awaiter(this, void 0, void 0, function () {
            var errorEntry, todoData, todoContent;
            return __generator(this, function (_a) {
                try {
                    errorEntry = {
                        timestamp: errorInfo.timestamp,
                        level: errorInfo.level,
                        component: errorInfo.component,
                        operation: errorInfo.operation,
                        error_message: errorInfo.error_message,
                        stack_trace: errorInfo.stack_trace || '',
                        context: errorInfo.context || {},
                        action: errorInfo.action || 'Investigate and fix the issue'
                    };
                    todoData = {};
                    try {
                        if (fs.existsSync(this.todoFilePath)) {
                            todoContent = fs.readFileSync(this.todoFilePath, 'utf8');
                            todoData = JSON.parse(todoContent);
                        }
                        else {
                            todoData = {
                                version: "1.0.0",
                                updated: new Date().toISOString(),
                                tasks: [],
                                errors: []
                            };
                        }
                    }
                    catch (readError) {
                        // If JSON parsing fails, create a new structure
                        todoData = {
                            version: "1.0.0",
                            updated: new Date().toISOString(),
                            tasks: [],
                            errors: []
                        };
                    }
                    // Add error entry
                    if (!todoData.errors) {
                        todoData.errors = [];
                    }
                    todoData.errors.push(errorEntry);
                    todoData.updated = new Date().toISOString();
                    // Write back to file
                    fs.writeFileSync(this.todoFilePath, JSON.stringify(todoData, null, 2), 'utf8');
                    console.error("Error logged to ".concat(this.todoFilePath));
                }
                catch (logError) {
                    console.error('Failed to log error to todo.yaml:', logError);
                }
                return [2 /*return*/];
            });
        });
    };
    /**
     * Create a new Redmine project
     * @param name - Project name
     * @param identifier - Project identifier (slug)
     * @param description - Project description
     * @param isPublic - Whether the project is public
     * @param parentId - ID of parent project for subproject creation
     * @returns Created project
     */
    RedmineClient.prototype.createProject = function (name_1, identifier_1, description_1) {
        return __awaiter(this, arguments, void 0, function (name, identifier, description, isPublic, parentId) {
            var errorMessage, errorMessage, data, parentProject, parentError_1, errorMessage, response, errorMessage, createdProject, errorMessage, parentProject, parentError_2, issueError_1, verifyError_1, error_1, errorMessage, errorDetails, axiosErrorDetails, parentIdErrors, issueError_2;
            var _a;
            if (isPublic === void 0) { isPublic = true; }
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        console.error("Creating project: \"".concat(name, "\", identifier: \"").concat(identifier, "\""));
                        console.error("Parameters: parentId=".concat(parentId || 'none', ", isPublic=").concat(isPublic, ", description=").concat(description ? "provided" : "undefined"));
                        if (!(!name || name.trim() === '')) return [3 /*break*/, 2];
                        errorMessage = 'Project name is required';
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createProject',
                                error_message: errorMessage,
                                context: { name: name, identifier: identifier, parentId: parentId }
                            })];
                    case 1:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 2:
                        if (!(!identifier || identifier.trim() === '')) return [3 /*break*/, 4];
                        errorMessage = 'Project identifier is required';
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createProject',
                                error_message: errorMessage,
                                context: { name: name, identifier: identifier, parentId: parentId }
                            })];
                    case 3:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 4:
                        data = {
                            project: {
                                name: name.trim(),
                                identifier: identifier.trim(),
                                is_public: isPublic
                            }
                        };
                        // Add optional parameters if specified
                        if (description !== undefined && description !== null) {
                            data.project.description = description;
                        }
                        if (!(parentId !== undefined && parentId !== null)) return [3 /*break*/, 9];
                        // Ensure parent_id is converted to a number - FIX: explicit Number conversion
                        data.project.parent_id = Number(parentId);
                        // Log the exact parent_id being sent for debugging - FIX: added for debugging
                        console.error("Setting parent_id: ".concat(data.project.parent_id, " (").concat(typeof data.project.parent_id, ")"));
                        _b.label = 5;
                    case 5:
                        _b.trys.push([5, 7, , 9]);
                        return [4 /*yield*/, this.getProject("id:".concat(parentId))];
                    case 6:
                        parentProject = _b.sent();
                        console.error("Parent project verified: ".concat(parentProject.name, " (ID: ").concat(parentProject.id, ")"));
                        return [3 /*break*/, 9];
                    case 7:
                        parentError_1 = _b.sent();
                        errorMessage = "Parent project with ID ".concat(parentId, " could not be found or accessed");
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createProject',
                                error_message: errorMessage,
                                context: { name: name, identifier: identifier, parentId: parentId }
                            })];
                    case 8:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 9:
                        // Log the exact payload being sent (for debugging)
                        console.error("Request payload: ".concat(JSON.stringify(data, null, 2)));
                        _b.label = 10;
                    case 10:
                        _b.trys.push([10, 28, , 34]);
                        return [4 /*yield*/, this.api.post('/projects.json', data, {
                                headers: {
                                    'X-Redmine-API-Key': this.apiKey,
                                    'Content-Type': 'application/json',
                                    'Accept': 'application/json'
                                }
                            })];
                    case 11:
                        response = _b.sent();
                        console.error("Response status: ".concat(response.status));
                        console.error("Response data: ".concat(JSON.stringify(response.data, null, 2)));
                        if (!(!response.data || !response.data.project)) return [3 /*break*/, 13];
                        errorMessage = 'Unexpected response format from Redmine API';
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createProject',
                                error_message: errorMessage,
                                context: {
                                    name: name,
                                    identifier: identifier,
                                    parentId: parentId,
                                    response: response.data
                                }
                            })];
                    case 12:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 13:
                        _b.trys.push([13, 25, , 27]);
                        // FIX: Wait longer (3 seconds) for parent project association to be established in database
                        return [4 /*yield*/, new Promise(function (resolve) { return setTimeout(resolve, 3000); })];
                    case 14:
                        // FIX: Wait longer (3 seconds) for parent project association to be established in database
                        _b.sent();
                        return [4 /*yield*/, this.getProject(identifier)];
                    case 15:
                        createdProject = _b.sent();
                        if (!(parentId && (!createdProject.parent || createdProject.parent.id !== parentId))) return [3 /*break*/, 24];
                        errorMessage = "Project created but not properly associated with parent ID ".concat(parentId);
                        console.error("Error: ".concat(errorMessage));
                        _b.label = 16;
                    case 16:
                        _b.trys.push([16, 18, , 19]);
                        return [4 /*yield*/, this.getProject("id:".concat(parentId))];
                    case 17:
                        parentProject = _b.sent();
                        console.error("Parent project exists: ".concat(parentProject.name));
                        return [3 /*break*/, 19];
                    case 18:
                        parentError_2 = _b.sent();
                        console.error("Error fetching parent project: ".concat(parentError_2.message));
                        return [3 /*break*/, 19];
                    case 19: 
                    // Log error to todo.yaml
                    return [4 /*yield*/, this.logError({
                            timestamp: new Date().toISOString(),
                            level: 'warning',
                            component: 'RedmineClient',
                            operation: 'createProject',
                            error_message: errorMessage,
                            context: {
                                name: name,
                                identifier: identifier,
                                expectedParentId: parentId,
                                createdProject: createdProject
                            },
                            action: 'Project may need to be manually moved to correct parent'
                        })];
                    case 20:
                        // Log error to todo.yaml
                        _b.sent();
                        _b.label = 21;
                    case 21:
                        _b.trys.push([21, 23, , 24]);
                        return [4 /*yield*/, this.createIssue(5, // bugs project ID
                            "Subproject Association Failed: ".concat(name), "\n## Automated Error Report\n\nA project was created but failed to associate with its parent project.\n\n**Project Name:** ".concat(name, "\n**Project Identifier:** ").concat(identifier, "\n**Expected Parent ID:** ").concat(parentId, "\n**Created Project ID:** ").concat(createdProject.id, "\n\n### Details\n\nThe project was successfully created in Redmine but the parent-child relationship was not established correctly. The project may need to be manually moved to the correct parent.\n              "), 1, // Bug tracker ID
                            1, // New status ID
                            3 // High priority ID
                            )];
                    case 22:
                        _b.sent();
                        return [3 /*break*/, 24];
                    case 23:
                        issueError_1 = _b.sent();
                        console.error("Failed to create error issue: ".concat(issueError_1.message));
                        return [3 /*break*/, 24];
                    case 24: return [2 /*return*/, createdProject];
                    case 25:
                        verifyError_1 = _b.sent();
                        // Project was created but verification failed
                        console.error("Warning: Project created but verification failed:", verifyError_1);
                        // Log warning to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'warning',
                                component: 'RedmineClient',
                                operation: 'createProject',
                                error_message: "Project created but verification failed: ".concat(verifyError_1.message),
                                context: {
                                    name: name,
                                    identifier: identifier,
                                    parentId: parentId,
                                    createdProjectId: response.data.project.id
                                },
                                action: 'Verify project was created correctly'
                            })];
                    case 26:
                        // Log warning to todo.yaml
                        _b.sent();
                        // Return the project data anyway since it was created
                        return [2 /*return*/, response.data.project];
                    case 27: return [3 /*break*/, 34];
                    case 28:
                        error_1 = _b.sent();
                        console.error('Error creating project:', error_1);
                        errorMessage = "Failed to create Redmine project: ".concat(error_1.message);
                        errorDetails = {};
                        if (axios_1.default.isAxiosError(error_1)) {
                            if (error_1.response) {
                                console.error("Status: ".concat(error_1.response.status));
                                console.error("Response headers: ".concat(JSON.stringify(error_1.response.headers, null, 2)));
                                console.error("Response data: ".concat(JSON.stringify(error_1.response.data, null, 2)));
                                axiosErrorDetails = ((_a = error_1.response.data) === null || _a === void 0 ? void 0 : _a.errors) || [];
                                if (axiosErrorDetails.length > 0) {
                                    console.error("Specific errors: ".concat(JSON.stringify(axiosErrorDetails, null, 2)));
                                    parentIdErrors = axiosErrorDetails.filter(function (e) {
                                        return typeof e === 'string' && e.toLowerCase().includes('parent');
                                    });
                                    if (parentIdErrors.length > 0) {
                                        errorMessage = "Failed to create subproject: ".concat(parentIdErrors.join(', '));
                                        errorDetails = { parent_errors: parentIdErrors };
                                    }
                                    else {
                                        errorMessage = "Failed to create Redmine project: ".concat(axiosErrorDetails.join(', '));
                                        errorDetails = { errors: axiosErrorDetails };
                                    }
                                }
                            }
                            else if (error_1.request) {
                                console.error('Error: No response received from server');
                                console.error("Request details: ".concat(JSON.stringify(error_1.request, null, 2)));
                                errorDetails = { request: 'No response received from server' };
                            }
                            else {
                                console.error("Error setting up request: ".concat(error_1.message));
                                errorDetails = { setup: error_1.message };
                            }
                            // Include request details in error message
                            console.error("Request config: ".concat(JSON.stringify(error_1.config, null, 2)));
                        }
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createProject',
                                error_message: errorMessage,
                                stack_trace: error_1.stack,
                                context: {
                                    name: name,
                                    identifier: identifier,
                                    parentId: parentId,
                                    request: data,
                                    errorDetails: errorDetails
                                }
                            })];
                    case 29:
                        // Log error to todo.yaml
                        _b.sent();
                        _b.label = 30;
                    case 30:
                        _b.trys.push([30, 32, , 33]);
                        return [4 /*yield*/, this.createIssue(5, // bugs project ID
                            "Project Creation Failed: ".concat(name), "\n## Automated Error Report\n\nFailed to create project in Redmine.\n\n**Project Name:** ".concat(name, "\n**Project Identifier:** ").concat(identifier, "\n**Parent ID:** ").concat(parentId || 'None', "\n\n### Error Details\n```\n").concat(errorMessage, "\n```\n\n### Request Data\n```json\n").concat(JSON.stringify(data, null, 2), "\n```\n\n### Error Details\n```json\n").concat(JSON.stringify(errorDetails, null, 2), "\n```\n          "), 1, // Bug tracker ID
                            1, // New status ID
                            3 // High priority ID
                            )];
                    case 31:
                        _b.sent();
                        return [3 /*break*/, 33];
                    case 32:
                        issueError_2 = _b.sent();
                        console.error("Failed to create error issue: ".concat(issueError_2.message));
                        return [3 /*break*/, 33];
                    case 33: throw new Error(errorMessage);
                    case 34: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Get a list of projects
     * @param limit - Maximum number of projects to return
     * @param offset - Pagination offset
     * @param sort - Sort field and direction (field:direction)
     * @returns List of projects
     */
    RedmineClient.prototype.getProjects = function () {
        return __awaiter(this, arguments, void 0, function (limit, offset, sort) {
            var params, _a, field, direction, response, error_2;
            if (limit === void 0) { limit = 25; }
            if (offset === void 0) { offset = 0; }
            if (sort === void 0) { sort = 'name:asc'; }
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        console.error("Fetching projects (limit: ".concat(limit, ", offset: ").concat(offset, ")"));
                        params = {
                            limit: limit,
                            offset: offset
                        };
                        // Parse sort parameter (field:direction)
                        if (sort && sort.includes(':')) {
                            _a = sort.split(':'), field = _a[0], direction = _a[1];
                            params.sort = field;
                            params.order = direction;
                        }
                        _b.label = 1;
                    case 1:
                        _b.trys.push([1, 3, , 5]);
                        return [4 /*yield*/, this.api.get('/projects.json', { params: params })];
                    case 2:
                        response = _b.sent();
                        return [2 /*return*/, response.data.projects];
                    case 3:
                        error_2 = _b.sent();
                        console.error('Error fetching projects:', error_2);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'getProjects',
                                error_message: "Failed to fetch Redmine projects: ".concat(error_2.message),
                                context: { limit: limit, offset: offset, sort: sort }
                            })];
                    case 4:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error("Failed to fetch Redmine projects: ".concat(error_2.message));
                    case 5: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Get a specific project by identifier
     * @param identifier - Project identifier
     * @param includeData - Additional data to include
     * @returns Project details
     */
    RedmineClient.prototype.getProject = function (identifier_1) {
        return __awaiter(this, arguments, void 0, function (identifier, includeData) {
            var params, response, error_3;
            if (includeData === void 0) { includeData = []; }
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.error("Fetching project: ".concat(identifier));
                        params = {};
                        // Add include parameter if specified
                        if (includeData.length > 0) {
                            params.include = includeData.join(',');
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 5]);
                        return [4 /*yield*/, this.api.get("/projects/".concat(identifier, ".json"), { params: params })];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.data.project];
                    case 3:
                        error_3 = _a.sent();
                        console.error("Error fetching project ".concat(identifier, ":"), error_3);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'getProject',
                                error_message: "Failed to fetch Redmine project: ".concat(error_3.message),
                                context: { identifier: identifier, includeData: includeData }
                            })];
                    case 4:
                        // Log error to todo.yaml
                        _a.sent();
                        throw new Error("Failed to fetch Redmine project: ".concat(error_3.message));
                    case 5: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Get a list of issues
     * @param projectId - Optional project identifier to filter issues
     * @param statusId - Optional status ID to filter issues
     * @param trackerId - Optional tracker ID to filter issues
     * @param limit - Maximum number of issues to return
     * @param offset - Pagination offset
     * @param sort - Sort field and direction (field:direction)
     * @returns List of issues
     */
    RedmineClient.prototype.getIssues = function (projectId_1, statusId_1, trackerId_1) {
        return __awaiter(this, arguments, void 0, function (projectId, statusId, trackerId, limit, offset, sort) {
            var params, _a, field, direction, endpoint, response, error_4;
            if (limit === void 0) { limit = 25; }
            if (offset === void 0) { offset = 0; }
            if (sort === void 0) { sort = 'updated_on:desc'; }
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        console.error("Fetching issues (project: ".concat(projectId || 'all', ", limit: ").concat(limit, ", offset: ").concat(offset, ")"));
                        params = {
                            limit: limit,
                            offset: offset
                        };
                        // Add filters if specified
                        if (projectId)
                            params.project_id = projectId;
                        if (statusId)
                            params.status_id = statusId;
                        if (trackerId)
                            params.tracker_id = trackerId;
                        // Parse sort parameter (field:direction)
                        if (sort && sort.includes(':')) {
                            _a = sort.split(':'), field = _a[0], direction = _a[1];
                            params.sort = field;
                            params.order = direction;
                        }
                        _b.label = 1;
                    case 1:
                        _b.trys.push([1, 3, , 5]);
                        endpoint = projectId ? "/projects/".concat(projectId, "/issues.json") : '/issues.json';
                        return [4 /*yield*/, this.api.get(endpoint, { params: params })];
                    case 2:
                        response = _b.sent();
                        return [2 /*return*/, response.data.issues];
                    case 3:
                        error_4 = _b.sent();
                        console.error('Error fetching issues:', error_4);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'getIssues',
                                error_message: "Failed to fetch Redmine issues: ".concat(error_4.message),
                                context: { projectId: projectId, statusId: statusId, trackerId: trackerId, limit: limit, offset: offset, sort: sort }
                            })];
                    case 4:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error("Failed to fetch Redmine issues: ".concat(error_4.message));
                    case 5: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Get a specific issue by ID
     * @param issueId - Issue ID
     * @param includeData - Additional data to include
     * @returns Issue details
     */
    RedmineClient.prototype.getIssue = function (issueId_1) {
        return __awaiter(this, arguments, void 0, function (issueId, includeData) {
            var params, response, error_5;
            if (includeData === void 0) { includeData = []; }
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.error("Fetching issue: ".concat(issueId));
                        params = {};
                        // Add include parameter if specified
                        if (includeData.length > 0) {
                            params.include = includeData.join(',');
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 5]);
                        return [4 /*yield*/, this.api.get("/issues/".concat(issueId, ".json"), { params: params })];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.data.issue];
                    case 3:
                        error_5 = _a.sent();
                        console.error("Error fetching issue ".concat(issueId, ":"), error_5);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'getIssue',
                                error_message: "Failed to fetch Redmine issue: ".concat(error_5.message),
                                context: { issueId: issueId, includeData: includeData }
                            })];
                    case 4:
                        // Log error to todo.yaml
                        _a.sent();
                        throw new Error("Failed to fetch Redmine issue: ".concat(error_5.message));
                    case 5: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Create a new issue
     * @param projectId - Project ID
     * @param subject - Issue subject
     * @param description - Issue description
     * @param trackerId - Tracker ID
     * @param statusId - Status ID
     * @param priorityId - Priority ID
     * @param assignedToId - Assignee ID
     * @returns Created issue
     */
    RedmineClient.prototype.createIssue = function (projectId, subject, description, trackerId, statusId, priorityId, assignedToId) {
        return __awaiter(this, void 0, void 0, function () {
            var errorMessage, errorMessage, data, url, errorMessage, response, errorMessage, error_6, errorMessage, errorDetails, axiosErrorDetails;
            var _a;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        console.error("Creating issue: \"".concat(subject, "\" for project ").concat(projectId));
                        console.error("Parameters: projectId=".concat(projectId, ", subject=\"").concat(subject, "\", description=").concat(description ? "provided" : "undefined"));
                        console.error("Parameters: trackerId=".concat(trackerId, ", statusId=").concat(statusId, ", priorityId=").concat(priorityId, ", assignedToId=").concat(assignedToId));
                        if (!!projectId) return [3 /*break*/, 2];
                        errorMessage = 'Project ID is required';
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createIssue',
                                error_message: errorMessage,
                                context: { projectId: projectId, subject: subject }
                            })];
                    case 1:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 2:
                        if (!(!subject || subject.trim() === '')) return [3 /*break*/, 4];
                        errorMessage = 'Subject is required';
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createIssue',
                                error_message: errorMessage,
                                context: { projectId: projectId, subject: subject }
                            })];
                    case 3:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 4:
                        data = {
                            issue: {
                                project_id: projectId,
                                subject: subject.trim()
                            }
                        };
                        // Add optional parameters if specified - with type checking
                        if (description !== undefined && description !== null) {
                            data.issue.description = description;
                        }
                        if (trackerId !== undefined && trackerId !== null) {
                            data.issue.tracker_id = Number(trackerId);
                        }
                        if (statusId !== undefined && statusId !== null) {
                            data.issue.status_id = Number(statusId);
                        }
                        if (priorityId !== undefined && priorityId !== null) {
                            data.issue.priority_id = Number(priorityId);
                        }
                        if (assignedToId !== undefined && assignedToId !== null) {
                            data.issue.assigned_to_id = Number(assignedToId);
                        }
                        // Log the exact payload being sent (for debugging)
                        console.error("Request payload: ".concat(JSON.stringify(data, null, 2)));
                        _b.label = 5;
                    case 5:
                        _b.trys.push([5, 11, , 13]);
                        url = '/issues.json';
                        console.error("Making POST request to: ".concat(this.baseUrl).concat(url));
                        if (!!this.apiKey) return [3 /*break*/, 7];
                        errorMessage = 'API key is not configured';
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'critical',
                                component: 'RedmineClient',
                                operation: 'createIssue',
                                error_message: errorMessage,
                                context: { projectId: projectId, subject: subject }
                            })];
                    case 6:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 7: return [4 /*yield*/, this.api.post(url, data, {
                            headers: {
                                'X-Redmine-API-Key': this.apiKey,
                                'Content-Type': 'application/json',
                                'Accept': 'application/json'
                            }
                        })];
                    case 8:
                        response = _b.sent();
                        console.error("Response status: ".concat(response.status));
                        console.error("Response data: ".concat(JSON.stringify(response.data, null, 2)));
                        if (!(!response.data || !response.data.issue)) return [3 /*break*/, 10];
                        errorMessage = 'Unexpected response format from Redmine API';
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createIssue',
                                error_message: errorMessage,
                                context: {
                                    projectId: projectId,
                                    subject: subject,
                                    response: response.data
                                }
                            })];
                    case 9:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 10: return [2 /*return*/, response.data.issue];
                    case 11:
                        error_6 = _b.sent();
                        console.error('Error creating issue:', error_6);
                        errorMessage = "Failed to create Redmine issue: ".concat(error_6.message);
                        errorDetails = {};
                        if (axios_1.default.isAxiosError(error_6)) {
                            if (error_6.response) {
                                console.error("Status: ".concat(error_6.response.status));
                                console.error("Response headers: ".concat(JSON.stringify(error_6.response.headers, null, 2)));
                                console.error("Response data: ".concat(JSON.stringify(error_6.response.data, null, 2)));
                                axiosErrorDetails = ((_a = error_6.response.data) === null || _a === void 0 ? void 0 : _a.errors) || [];
                                if (axiosErrorDetails.length > 0) {
                                    console.error("Specific errors: ".concat(JSON.stringify(axiosErrorDetails, null, 2)));
                                    errorMessage = "Failed to create Redmine issue: ".concat(axiosErrorDetails.join(', '));
                                    errorDetails = { errors: axiosErrorDetails };
                                }
                            }
                            else if (error_6.request) {
                                console.error('Error: No response received from server');
                                console.error("Request details: ".concat(JSON.stringify(error_6.request, null, 2)));
                                errorDetails = { request: 'No response received from server' };
                            }
                            else {
                                console.error("Error setting up request: ".concat(error_6.message));
                                errorDetails = { setup: error_6.message };
                            }
                            // Include request details in error message
                            console.error("Request config: ".concat(JSON.stringify(error_6.config, null, 2)));
                        }
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'createIssue',
                                error_message: errorMessage,
                                stack_trace: error_6.stack,
                                context: {
                                    projectId: projectId,
                                    subject: subject,
                                    trackerId: trackerId,
                                    statusId: statusId,
                                    priorityId: priorityId,
                                    assignedToId: assignedToId,
                                    request: data,
                                    errorDetails: errorDetails
                                }
                            })];
                    case 12:
                        // Log error to todo.yaml
                        _b.sent();
                        throw new Error(errorMessage);
                    case 13: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Update an existing issue
     * @param issueId - Issue ID
     * @param params - Parameters to update
     * @returns True if successful
     */
    RedmineClient.prototype.updateIssue = function (issueId, params) {
        return __awaiter(this, void 0, void 0, function () {
            var currentIssue, completeParams_1, response, updatedIssue, errorMessage, verifyError_2, error_7, response, error_8;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.error("Updating issue: ".concat(issueId));
                        console.error("Update parameters: ".concat(JSON.stringify(params, null, 2)));
                        if (!(params.project_id !== undefined)) return [3 /*break*/, 15];
                        console.error("Moving issue to project_id: ".concat(params.project_id));
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 12, , 14]);
                        return [4 /*yield*/, this.getIssue(issueId)];
                    case 2:
                        currentIssue = _a.sent();
                        console.error("Current issue data: ".concat(JSON.stringify(currentIssue, null, 2)));
                        completeParams_1 = {
                            project_id: params.project_id,
                            tracker_id: currentIssue.tracker.id,
                            status_id: currentIssue.status.id,
                            priority_id: currentIssue.priority.id,
                            subject: currentIssue.subject,
                        };
                        // Add description if available
                        if (currentIssue.description) {
                            completeParams_1.description = currentIssue.description;
                        }
                        // Override with any new values provided in params
                        Object.keys(params).forEach(function (key) {
                            if (params[key] !== undefined) {
                                completeParams_1[key] = params[key];
                            }
                        });
                        console.error("Complete update parameters: ".concat(JSON.stringify(completeParams_1, null, 2)));
                        // Include the notes parameter to log the project change
                        if (!completeParams_1.notes) {
                            completeParams_1.notes = "Moved to project ID: ".concat(params.project_id);
                        }
                        return [4 /*yield*/, this.api.put("/issues/".concat(issueId, ".json"), {
                                issue: completeParams_1
                            })];
                    case 3:
                        response = _a.sent();
                        console.error("Update response: ".concat(JSON.stringify(response.data, null, 2)));
                        _a.label = 4;
                    case 4:
                        _a.trys.push([4, 9, , 11]);
                        // Wait a moment to ensure the update is processed
                        return [4 /*yield*/, new Promise(function (resolve) { return setTimeout(resolve, 1000); })];
                    case 5:
                        // Wait a moment to ensure the update is processed
                        _a.sent();
                        return [4 /*yield*/, this.getIssue(issueId)];
                    case 6:
                        updatedIssue = _a.sent();
                        if (!(updatedIssue.project.id !== params.project_id)) return [3 /*break*/, 8];
                        errorMessage = "Issue was not properly moved to project ID ".concat(params.project_id);
                        console.error("Error: ".concat(errorMessage));
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'warning',
                                component: 'RedmineClient',
                                operation: 'updateIssue',
                                error_message: errorMessage,
                                context: {
                                    issueId: issueId,
                                    targetProjectId: params.project_id,
                                    currentProjectId: updatedIssue.project.id
                                },
                                action: 'Issue may need to be manually moved to correct project'
                            })];
                    case 7:
                        // Log error to todo.yaml
                        _a.sent();
                        _a.label = 8;
                    case 8: return [3 /*break*/, 11];
                    case 9:
                        verifyError_2 = _a.sent();
                        console.error("Warning: Unable to verify issue transfer:", verifyError_2);
                        // Log warning to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'warning',
                                component: 'RedmineClient',
                                operation: 'updateIssue',
                                error_message: "Unable to verify issue transfer: ".concat(verifyError_2.message),
                                context: {
                                    issueId: issueId,
                                    targetProjectId: params.project_id
                                },
                                action: 'Verify issue was moved correctly'
                            })];
                    case 10:
                        // Log warning to todo.yaml
                        _a.sent();
                        return [3 /*break*/, 11];
                    case 11: return [2 /*return*/, true];
                    case 12:
                        error_7 = _a.sent();
                        console.error("Error updating issue ".concat(issueId, " with project change:"), error_7);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'updateIssue',
                                error_message: "Failed to update Redmine issue with project change: ".concat(error_7.message),
                                stack_trace: error_7.stack,
                                context: {
                                    issueId: issueId,
                                    params: params
                                }
                            })];
                    case 13:
                        // Log error to todo.yaml
                        _a.sent();
                        if (axios_1.default.isAxiosError(error_7) && error_7.response) {
                            console.error("Status: ".concat(error_7.response.status));
                            console.error("Response data: ".concat(JSON.stringify(error_7.response.data, null, 2)));
                        }
                        throw new Error("Failed to update Redmine issue with project change: ".concat(error_7.message));
                    case 14: return [3 /*break*/, 19];
                    case 15:
                        _a.trys.push([15, 17, , 19]);
                        return [4 /*yield*/, this.api.put("/issues/".concat(issueId, ".json"), { issue: params })];
                    case 16:
                        response = _a.sent();
                        console.error("Update response status: ".concat(response.status));
                        return [2 /*return*/, true];
                    case 17:
                        error_8 = _a.sent();
                        console.error("Error updating issue ".concat(issueId, ":"), error_8);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'updateIssue',
                                error_message: "Failed to update Redmine issue: ".concat(error_8.message),
                                context: {
                                    issueId: issueId,
                                    params: params
                                }
                            })];
                    case 18:
                        // Log error to todo.yaml
                        _a.sent();
                        if (axios_1.default.isAxiosError(error_8) && error_8.response) {
                            console.error("Status: ".concat(error_8.response.status));
                            console.error("Response data: ".concat(JSON.stringify(error_8.response.data, null, 2)));
                        }
                        throw new Error("Failed to update Redmine issue: ".concat(error_8.message));
                    case 19: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Get current user information
     * @returns Current user details
     */
    RedmineClient.prototype.getCurrentUser = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, error_9;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.error('Fetching current user info');
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 5]);
                        return [4 /*yield*/, this.api.get('/users/current.json')];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.data.user];
                    case 3:
                        error_9 = _a.sent();
                        console.error('Error fetching current user:', error_9);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'getCurrentUser',
                                error_message: "Failed to fetch current Redmine user: ".concat(error_9.message)
                            })];
                    case 4:
                        // Log error to todo.yaml
                        _a.sent();
                        throw new Error("Failed to fetch current Redmine user: ".concat(error_9.message));
                    case 5: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Test connection to Redmine
     * @returns True if connection successful
     */
    RedmineClient.prototype.testConnection = function () {
        return __awaiter(this, void 0, void 0, function () {
            var error_10;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.error('Testing connection to Redmine');
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 5]);
                        // Connect to a specific endpoint instead of root
                        return [4 /*yield*/, this.api.get('/projects.json')];
                    case 2:
                        // Connect to a specific endpoint instead of root
                        _a.sent();
                        console.error('Connection successful');
                        return [2 /*return*/, true];
                    case 3:
                        error_10 = _a.sent();
                        console.error('Connection failed:', error_10);
                        // Log error to todo.yaml
                        return [4 /*yield*/, this.logError({
                                timestamp: new Date().toISOString(),
                                level: 'error',
                                component: 'RedmineClient',
                                operation: 'testConnection',
                                error_message: "Failed to connect to Redmine: ".concat(error_10.message)
                            })];
                    case 4:
                        // Log error to todo.yaml
                        _a.sent();
                        throw new Error("Failed to connect to Redmine: ".concat(error_10.message));
                    case 5: return [2 /*return*/];
                }
            });
        });
    };
    return RedmineClient;
}());
exports.RedmineClient = RedmineClient;
