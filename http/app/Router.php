<?php

namespace App;

use App\Contracts\Request;

#[\AllowDynamicProperties]
class Router
{
    protected $request;

    protected $supportedHttpMethods = [
        'GET',
        'POST',
    ];

    public function __construct(Request $request)
    {
        $this->request = $request;
    }

    public function __call($name, $args)
    {
        list($route, $method) = $args;
        if (! \in_array(\strtoupper($name), $this->supportedHttpMethods)) {
            $this->invalidMethodHandler();
        }
        $this->{\strtolower($name)}[$this->formatRoute($route)] = $method;
    }

    /**
     * Removes trailing forward slashes from the right of the route.
     *
     * @param route (string)
     */
    private function formatRoute($route)
    {
        $result = \rtrim($route, '/');
        if ($result === '') {
            return '/';
        }

        $uriParts = \explode('?', $route, 2);

        return $uriParts[0];
    }

    private function invalidMethodHandler()
    {
        \header("{$this->request->serverProtocol} 405 Method Not Allowed");
    }

    private function defaultRequestHandler()
    {
        \header("{$this->request->serverProtocol} 404 Not Found");

        if ($this->request->requestUri != '/404') {
            $this->request->setMethod('GET');
            $this->request->setUri('/404');
            $this->resolve();
        }
    }

    /**
     * Resolves a route.
     */
    public function resolve()
    {
        $methodDictionary = $this->{\strtolower($this->request->requestMethod)};
        $formatedRoute = $this->formatRoute($this->request->requestUri);
        $method = $methodDictionary[$formatedRoute] ? $methodDictionary[$formatedRoute] : null;
        if (\is_null($method)) {
            $this->defaultRequestHandler();

            return;
        }

        $routeReturn = \call_user_func_array($method, [$this->request]);

        if (\is_string($routeReturn)) {
            echo $routeReturn;

            return;
        }

        if (\is_object($routeReturn)) {
            $routeReturn = $routeReturn($this->request);
        }

        if (\is_array($routeReturn)) {
            \header('Content-Type: application/json');
            echo \json_encode($routeReturn);

            return;
        }

        echo $routeReturn;
    }

    public function __destruct()
    {
        $this->resolve();
    }
}
