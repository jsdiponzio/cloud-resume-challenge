import unittest
from main import increment_fetch
from mockfirestore import MockFirestore

class TestIncrementFetch(unittest.TestCase):

	def test_count_not_null(self):
		data = {
			u'visitor-count': 3
		}
		mock_db = MockFirestore()
		mock_db.collection(u'site-views').document(u'visitors').set(data)
		updated_count, status_code, headers = increment_fetch(request="request", test=mock_db)
		self.assertIsNotNone(updated_count)

	def test_count_is_str(self):
		data = {
			u'visitor-count': 3
		}
		mock_db = MockFirestore()
		mock_db.collection(u'site-views').document(u'visitors').set(data)
		updated_count, status_code, headers = increment_fetch(request="request", test=mock_db)
		self.assertIsInstance(updated_count, str)	

	def test_count_increments(self):
		data = {
			u'visitor-count': 3
		}
		mock_db = MockFirestore()
		mock_db.collection(u'site-views').document(u'visitors').set(data)
		updated_count, status_code, headers = increment_fetch(request="request", test=mock_db)
		self.assertEqual(int(updated_count), 4)
	
	def test_status_200(self):
		data = {
			u'visitor-count': 3
		}
		mock_db = MockFirestore()
		mock_db.collection(u'site-views').document(u'visitors').set(data)
		updated_count, status_code, headers = increment_fetch(request="request", test=mock_db)
		self.assertEqual(status_code, 200)	

	def test_headers_not_null(self):
		data = {
			u'visitor-count': 3
		}
		mock_db = MockFirestore()
		mock_db.collection(u'site-views').document(u'visitors').set(data)
		updated_count, status_code, headers = increment_fetch(request="request", test=mock_db)
		self.assertIsNotNone(headers)	


if __name__ == '__main__':
  unittest.main()

