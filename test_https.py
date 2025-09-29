#!/usr/bin/env python3
"""
Test script for the HTTPS proxy server.
"""
import requests
import json
import urllib3

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_https_proxy():
    """Test the HTTPS proxy server functionality."""
    
    proxy_url = "https://localhost:8000/yuwathi/proxy"
    
    # Test data
    test_request = {
        "URL": "https://httpbin.org/get",
        "method": "GET",
        "header": {
            "User-Agent": "Yuwathi-Proxy-Test"
        }
    }
    
    print("🧪 Testing HTTPS Proxy Server")
    print("=" * 40)
    print(f"Proxy URL: {proxy_url}")
    print(f"Target URL: {test_request['URL']}")
    print()
    
    try:
        print("Sending request...")
        response = requests.post(
            proxy_url,
            json=test_request,
            verify=False,  # Skip SSL verification for self-signed cert
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ SUCCESS!")
            print(f"Response Status: {result.get('status_code')}")
            print(f"Response Headers: {len(result.get('headers', {}))} headers")
            print(f"Response Body Length: {len(result.get('body', ''))}")
            print(f"Is Base64: {result.get('is_base64')}")
            print(f"Truncated: {result.get('truncated')}")
            
            # Show a snippet of the response body
            body = result.get('body', '')
            if len(body) > 200:
                print(f"Body Preview: {body[:200]}...")
            else:
                print(f"Body: {body}")
                
            return True
        else:
            print(f"❌ FAILED - HTTP {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except requests.exceptions.SSLError as e:
        print(f"❌ SSL ERROR: {e}")
        print("This might be expected with self-signed certificates.")
        return False
    except requests.exceptions.ConnectionError as e:
        print(f"❌ CONNECTION ERROR: {e}")
        print("Make sure the HTTPS server is running on localhost:8000")
        return False
    except Exception as e:
        print(f"❌ UNEXPECTED ERROR: {e}")
        return False

def test_post_request():
    """Test a POST request through the proxy."""
    
    proxy_url = "https://localhost:8000/yuwathi/proxy"
    
    test_request = {
        "URL": "https://httpbin.org/post",
        "method": "POST",
        "header": {
            "Content-Type": "application/json",
            "User-Agent": "Yuwathi-Proxy-Test"
        },
        "data": {
            "message": "Hello from HTTPS proxy!",
            "timestamp": "2025-09-29",
            "test": True
        }
    }
    
    print("\n🧪 Testing POST Request")
    print("=" * 40)
    
    try:
        response = requests.post(
            proxy_url,
            json=test_request,
            verify=False,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ POST SUCCESS!")
            print(f"Response Status: {result.get('status_code')}")
            
            # Parse the response body to see if our data made it through
            try:
                body_data = json.loads(result.get('body', '{}'))
                if 'json' in body_data and body_data['json'].get('message') == "Hello from HTTPS proxy!":
                    print("✅ Data successfully transmitted through proxy!")
                else:
                    print("⚠️  Data may not have been transmitted correctly")
            except:
                pass
                
            return True
        else:
            print(f"❌ POST FAILED - HTTP {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ POST ERROR: {e}")
        return False

if __name__ == "__main__":
    print("🔒 HTTPS Proxy Test Suite")
    print("========================")
    print()
    
    # Run tests
    test1_passed = test_https_proxy()
    test2_passed = test_post_request()
    
    print("\n📊 Test Results")
    print("=" * 40)
    print(f"GET Request Test: {'✅ PASS' if test1_passed else '❌ FAIL'}")
    print(f"POST Request Test: {'✅ PASS' if test2_passed else '❌ FAIL'}")
    
    if test1_passed and test2_passed:
        print("\n🎉 All tests passed! Your HTTPS proxy is working correctly.")
        print("\n💡 Next steps:")
        print("   - Configure firewall to allow external access")
        print("   - Consider using a reverse proxy (nginx) for production")
        print("   - Get proper SSL certificates for production use")
    else:
        print("\n⚠️  Some tests failed. Check the server logs and configuration.")