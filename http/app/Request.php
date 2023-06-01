<?php

namespace App;

use App\Contracts\Request as RequestContract;
use InvalidArgumentException;

#[\AllowDynamicProperties]
class Request implements RequestContract
{
    public function __construct()
    {
        $this->bootstrapSelf();
    }

    private function bootstrapSelf()
    {
        foreach ($_SERVER as $key => $value) {
            $this->{$this->toCamelCase($key)} = $value;
        }
    }

    private function toCamelCase($string)
    {
        $result = \strtolower($string);

        \preg_match_all('/_[a-z]/', $result, $matches);
        foreach ($matches[0] as $match) {
            $c = \str_replace('_', '', \strtoupper($match));
            $result = \str_replace($match, $c, $result);
        }

        return $result;
    }

    public function getBody()
    {
        if ($this->method('GET')) {
            return;
        }

        if ($this->method('POST')) {
            $body = [];
            foreach ($_POST as $key => $value) {
                $body[$key] = \filter_input(INPUT_POST, $key, FILTER_SANITIZE_SPECIAL_CHARS);
            }

            return $body;
        }
    }

    public function setMethod($method)
    {
        if (! \in_array($method, ['POST', 'GET'])) {
            throw new InvalidArgumentException("The HTTP method \"{$method}\" is not supported.");
        }

        $this->requestMethod = $method;
    }

    public function setUri($uri)
    {
        $this->requestUri = $uri;
    }

    public function input($key, $default = null)
    {
        $variables = \array_merge($_GET, $_POST);

        $value = isset($variables[$key]) ? $variables[$key] : null;

        return ! empty($value) ? $value : $default;
    }

    /**
     * Returns the current method or validates the provided method passed as a parameter.
     *
     * @param string $matchMethod
     *
     * @return bool|string
     */
    public function method($matchMethod = null)
    {
        $method = \strtoupper($this->requestMethod);

        if (\is_null($matchMethod)) {
            return $method;
        }

        return \strtoupper($matchMethod) == $method;
    }
}
