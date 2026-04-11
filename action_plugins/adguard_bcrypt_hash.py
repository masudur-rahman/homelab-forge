from ansible.plugins.action import ActionBase
import bcrypt, json, os

class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):
        if task_vars is None:
            task_vars = {}
        result = super().run(tmp, task_vars)

        password = self._task.args.get('password', '').encode()
        current_hash = self._task.args.get('current_hash', '').encode()

        if not current_hash or not bcrypt.checkpw(password, current_hash):
            new_hash = bcrypt.hashpw(password, bcrypt.gensalt()).decode()
            result['hash'] = new_hash
            result['changed'] = True
        else:
            result['hash'] = current_hash.decode()
            result['changed'] = False
        result['rc'] = 0
        return result