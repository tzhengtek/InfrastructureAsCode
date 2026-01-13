from flask import Blueprint, request, jsonify
from .status_codes import StatusCode
from .common import require_auth, parse_request_timestamp, app_config
from datetime import timezone

bp = Blueprint('tasks', __name__)

# In-memory storage kept in module-level variables
tasks_storage = {}
task_counter = {'value': 0}


def validate_task_data(data, require_all=False):
    required_fields = ['title', 'content', 'due_date'] if require_all else []
    errors = []

    for field in required_fields:
        if field not in data or not data[field]:
            errors.append(f"Missing required field: {field}")

    if 'due_date' in data and data['due_date']:
        try:
            from datetime import datetime
            datetime.strptime(data['due_date'], '%Y-%m-%d')
        except ValueError:
            errors.append("Invalid due_date format. Expected YYYY-MM-DD")

    # request_timestamp format
    if 'request_timestamp' in data and data['request_timestamp']:
        try:
            parse_request_timestamp(data['request_timestamp'])
        except Exception:
            errors.append("Invalid request_timestamp format. Expected ISO 8601")

    if 'done' in data and data['done'] is not None:
        if not isinstance(data['done'], bool):
            errors.append("Field 'done' must be a boolean")

    return errors


@bp.route('/tasks', methods=['POST'])
@require_auth
def create_task():
    correlation_id = request.headers.get('correlation_id', 'unknown')
    # Trace incoming request
    from .common import logger
    logger.info(f"[{correlation_id}] POST /tasks incoming")
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Invalid request body'}), StatusCode.BAD_REQUEST

        errors = validate_task_data(data, require_all=True)
        if errors:
            return jsonify({'error': 'Validation failed', 'details': errors}), StatusCode.BAD_REQUEST

        if 'request_timestamp' not in data:
            return jsonify({'error': 'Missing required field: request_timestamp'}), StatusCode.BAD_REQUEST

        req_dt = parse_request_timestamp(data['request_timestamp'])

        # generate id
        task_counter['value'] += 1
        task_id = task_counter['value']

        task = {
            'id': task_id,
            'title': data['title'],
            'content': data['content'],
            'due_date': data['due_date'],
            'done': data.get('done', False),
            'request_timestamp': req_dt.replace(tzinfo=timezone.utc).isoformat().replace('+00:00', 'Z')
        }

        tasks_storage[task_id] = task
        logger.info(f"[{correlation_id}] Created task {task_id}")
        return jsonify(task), StatusCode.CREATED

    except Exception:
        return jsonify({'error': 'Internal server error'}), StatusCode.INTERNAL_SERVER_ERROR


@bp.route('/tasks', methods=['GET'])
@require_auth
def list_tasks():
    correlation_id = request.headers.get('correlation_id', 'unknown')
    from .common import logger
    try:
        logger.info(f"[{correlation_id}] GET /tasks incoming")
        sorted_tasks = sorted(tasks_storage.values(), key=lambda x: x.get('request_timestamp', ''))
        return jsonify(sorted_tasks), StatusCode.OK
    except Exception:
        logger.error(f"[{correlation_id}] Error listing tasks")
        return jsonify({'error': 'Internal server error'}), StatusCode.INTERNAL_SERVER_ERROR


@bp.route('/tasks/<int:task_id>', methods=['GET'])
@require_auth
def get_task(task_id):
    correlation_id = request.headers.get('correlation_id', 'unknown')
    from .common import logger
    try:
        logger.info(f"[{correlation_id}] GET /tasks/{task_id} incoming")
        if task_id not in tasks_storage:
            return jsonify({'error': 'Task not found'}), StatusCode.NOT_FOUND
        return jsonify(tasks_storage[task_id]), StatusCode.OK
    except Exception:
        logger.error(f"[{correlation_id}] Error getting task {task_id}")
        return jsonify({'error': 'Internal server error'}), StatusCode.INTERNAL_SERVER_ERROR


@bp.route('/tasks/<int:task_id>', methods=['PUT'])
@require_auth
def update_task(task_id):
    correlation_id = request.headers.get('correlation_id', 'unknown')
    from .common import logger
    logger.info(f"[{correlation_id}] PUT /tasks/{task_id} incoming")
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Invalid request body'}), StatusCode.BAD_REQUEST

        errors = validate_task_data(data)
        if errors:
            return jsonify({'error': 'Validation failed', 'details': errors}), StatusCode.BAD_REQUEST

        if 'request_timestamp' not in data:
            return jsonify({'error': 'Missing required field: request_timestamp'}), StatusCode.BAD_REQUEST

        req_dt = parse_request_timestamp(data['request_timestamp'])

        if task_id not in tasks_storage:
            return jsonify({'error': 'Task not found'}), StatusCode.NOT_FOUND

        task = tasks_storage[task_id]
        current_timestamp = parse_request_timestamp(task['request_timestamp'])
        
        # check last correlation if new older than last -> Conflict
        # if current_timestamp >= req_dt:
        #     logger.info(f"[{correlation_id}] Ignoring out-of-order request for task {task_id}")
        #     return jsonify({
        #         'error': 'Request timestamp is older than current task timestamp',
        #         'current_timestamp': task['request_timestamp'],
        #         'request_timestamp': data['request_timestamp']
        #     }), StatusCode.CONFLICT

        
        # update fields
        if 'title' in data:
            task['title'] = data['title']
        if 'content' in data:
            task['content'] = data['content']
        if 'due_date' in data:
            task['due_date'] = data['due_date']
        if 'done' in data:
            task['done'] = data['done']

        task['request_timestamp'] = req_dt.replace(tzinfo=timezone.utc).isoformat().replace('+00:00', 'Z')
        logger.info(f"[{correlation_id}] Updated task {task_id}")
        return jsonify(task), StatusCode.OK

    except Exception:
        return jsonify({'error': 'Internal server error'}), StatusCode.INTERNAL_SERVER_ERROR


@bp.route('/tasks/<int:task_id>', methods=['DELETE'])
@require_auth
def delete_task(task_id):
    correlation_id = request.headers.get('correlation_id', 'unknown')
    from .common import logger
    logger.info(f"[{correlation_id}] DELETE /tasks/{task_id} incoming")
    try:
        data = request.get_json() or {}
        if 'request_timestamp' not in data:
            return jsonify({'error': 'Missing required field: request_timestamp'}), StatusCode.BAD_REQUEST

        req_dt = parse_request_timestamp(data['request_timestamp'])

        if task_id not in tasks_storage:
            return jsonify({'error': 'Task not found'}), StatusCode.NOT_FOUND

        task = tasks_storage[task_id]
        # current_timestamp = parse_request_timestamp(task['request_timestamp'])
        # if current_timestamp >= req_dt:
        #     logger.info(f"[{correlation_id}] Ignoring out-of-order delete request for task {task_id}")
        #     return jsonify({
        #         'error': 'Request timestamp is older than current task timestamp',
        #         'current_timestamp': task['request_timestamp'],
        #         'request_timestamp': data['request_timestamp']
        #     }), StatusCode.CONFLICT

        deleted_task = tasks_storage.pop(task_id)
        logger.info(f"[{correlation_id}] Deleted task {task_id}")
        return jsonify(deleted_task), StatusCode.OK

    except Exception:
        return jsonify({'error': 'Internal server error'}), StatusCode.INTERNAL_SERVER_ERROR
